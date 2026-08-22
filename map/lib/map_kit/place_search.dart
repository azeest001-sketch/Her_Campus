import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';

import 'campus_boundary.dart';

/// A place returned from campus place search.
class PlaceResult {
  const PlaceResult({
    required this.displayName,
    required this.position,
    this.type,
    this.osmType,
    this.osmId,
    this.boundary,
  });

  final String displayName;
  final LatLng position;
  final String? type;

  /// Photon / OSM type: `N`, `W`, or `R`.
  final String? osmType;
  final int? osmId;

  /// Natural campus outline when already known (closed ring).
  final List<LatLng>? boundary;

  PlaceResult copyWith({List<LatLng>? boundary}) {
    return PlaceResult(
      displayName: displayName,
      position: position,
      type: type,
      osmType: osmType,
      osmId: osmId,
      boundary: boundary ?? this.boundary,
    );
  }
}

/// College / place search for the campus map setup flow.
///
/// Uses [Photon](https://photon.komoot.io) for search, then loads the natural
/// OSM campus polygon (not a square bounding box) via Nominatim lookup.
class PlaceSearch {
  PlaceSearch({
    http.Client? client,
    this.userAgent =
        'HerCampus/1.0 (campus-safety Flutter app; https://github.com/azeest001-sketch/Her_Campus)',
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String userAgent;

  static const _photonEndpoint = 'https://photon.komoot.io/api/';
  static const _nominatimSearch = 'https://nominatim.openstreetmap.org/search';
  static const _nominatimLookup = 'https://nominatim.openstreetmap.org/lookup';

  Future<List<PlaceResult>> search(
    String query, {
    int limit = 6,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    Object lastError = 'unknown error';

    try {
      final photon = await _searchPhoton(trimmed, limit: limit);
      if (photon.isNotEmpty) return photon;
    } catch (error) {
      lastError = error;
    }

    try {
      return await _searchNominatim(trimmed, limit: limit);
    } catch (error) {
      lastError = error;
    }

    throw Exception('Place search unavailable ($lastError)');
  }

  /// Loads the real campus footprint for a selected place.
  ///
  /// Prefers OSM way/relation polygons so the border follows the campus edge.
  /// Returns null when OpenStreetMap has no plausible campus shape — we do
  /// **not** invent a giant circle in that case.
  Future<List<LatLng>?> fetchNaturalBoundary(PlaceResult place) async {
    if (place.boundary != null && place.boundary!.length >= 4) {
      final existing = CampusBoundary.sanitize(
        place.boundary,
        near: place.position,
      );
      if (existing != null) return existing;
    }

    final fromLookup = await _lookupOsmPolygon(
      place.osmType,
      place.osmId,
      near: place.position,
    );
    if (fromLookup != null) return fromLookup;

    final fromName = await _searchNominatimPolygon(
      place.displayName,
      near: place.position,
    );
    if (fromName != null) return fromName;

    final shortName = place.displayName.split(',').first.trim();
    if (shortName.isNotEmpty && shortName != place.displayName) {
      final fromShort = await _searchNominatimPolygon(
        shortName,
        near: place.position,
      );
      if (fromShort != null) return fromShort;
    }

    return null;
  }

  Future<List<PlaceResult>> _searchPhoton(
    String query, {
    required int limit,
  }) async {
    final uri = Uri.parse(_photonEndpoint).replace(
      queryParameters: {
        'q': query,
        'limit': '$limit',
        'lang': 'en',
      },
    );

    final response = await _client
        .get(
          uri,
          headers: {
            'Accept': 'application/json',
            'User-Agent': userAgent,
          },
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Photon search failed (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return const [];
    final features = decoded['features'];
    if (features is! List) return const [];

    return features
        .whereType<Map>()
        .map((feature) {
          final geometry = feature['geometry'];
          final properties = feature['properties'];
          if (geometry is! Map || properties is! Map) return null;

          final coords = geometry['coordinates'];
          if (coords is! List || coords.length < 2) return null;

          final lon = (coords[0] as num?)?.toDouble();
          final lat = (coords[1] as num?)?.toDouble();
          if (lat == null || lon == null) return null;

          final name = _photonDisplayName(properties);
          if (name.isEmpty) return null;

          final osmType = _normalizeOsmType(properties['osm_type']);
          final osmId = int.tryParse('${properties['osm_id']}');

          return PlaceResult(
            displayName: name,
            position: LatLng(lat, lon),
            type: properties['type']?.toString() ??
                properties['osm_value']?.toString(),
            osmType: osmType,
            osmId: osmId,
          );
        })
        .whereType<PlaceResult>()
        .toList(growable: false);
  }

  Future<List<PlaceResult>> _searchNominatim(
    String query, {
    required int limit,
  }) async {
    final uri = Uri.parse(_nominatimSearch).replace(
      queryParameters: {
        'q': query,
        'format': 'json',
        'addressdetails': '0',
        'limit': '$limit',
        'polygon_geojson': '1',
      },
    );

    final response = await _client
        .get(
          uri,
          headers: {
            'User-Agent': userAgent,
            'Accept': 'application/json',
            'Accept-Language': 'en',
          },
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Nominatim search failed (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map>()
        .map((raw) {
          final lat = double.tryParse('${raw['lat']}');
          final lon = double.tryParse('${raw['lon']}');
          final name = raw['display_name']?.toString();
          if (lat == null || lon == null || name == null || name.isEmpty) {
            return null;
          }
          final osmType = _normalizeOsmType(raw['osm_type']);
          final osmId = int.tryParse('${raw['osm_id']}');
          return PlaceResult(
            displayName: name,
            position: LatLng(lat, lon),
            type: raw['type']?.toString(),
            osmType: osmType,
            osmId: osmId,
            // Only keep real campus-sized polygons — never a point or city blob.
            boundary: CampusBoundary.fromGeoJson(
              raw['geojson'],
              near: LatLng(lat, lon),
            ),
          );
        })
        .whereType<PlaceResult>()
        .toList(growable: false);
  }

  Future<List<LatLng>?> _lookupOsmPolygon(
    String? osmType,
    int? osmId, {
    LatLng? near,
  }) async {
    if (osmType == null || osmId == null) return null;
    // Nodes are points only — they never have a campus footprint.
    if (osmType == 'N') return null;

    final uri = Uri.parse(_nominatimLookup).replace(
      queryParameters: {
        'osm_ids': '$osmType$osmId',
        'format': 'json',
        'polygon_geojson': '1',
      },
    );

    try {
      final response = await _client
          .get(
            uri,
            headers: {
              'User-Agent': userAgent,
              'Accept': 'application/json',
              'Accept-Language': 'en',
            },
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.isEmpty) return null;
      final first = decoded.first;
      if (first is! Map) return null;
      return CampusBoundary.fromGeoJson(first['geojson'], near: near);
    } catch (_) {
      return null;
    }
  }

  Future<List<LatLng>?> _searchNominatimPolygon(
    String query, {
    required LatLng near,
  }) async {
    final uri = Uri.parse(_nominatimSearch).replace(
      queryParameters: {
        'q': query,
        'format': 'json',
        'addressdetails': '0',
        'limit': '8',
        'polygon_geojson': '1',
      },
    );

    try {
      final response = await _client
          .get(
            uri,
            headers: {
              'User-Agent': userAgent,
              'Accept': 'application/json',
              'Accept-Language': 'en',
            },
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return null;

      List<LatLng>? bestCampus;
      List<LatLng>? bestAny;

      for (final raw in decoded.whereType<Map>()) {
        final polygon = CampusBoundary.fromGeoJson(raw['geojson'], near: near);
        if (polygon == null) continue;

        final className = raw['class']?.toString().toLowerCase() ?? '';
        final typeName = raw['type']?.toString().toLowerCase() ?? '';
        final isCampusLike = typeName.contains('university') ||
            typeName.contains('college') ||
            typeName == 'school' ||
            (className == 'amenity' &&
                (typeName == 'university' || typeName == 'college')) ||
            (className == 'landuse' && typeName == 'education');

        // Skip city / admin boundaries even if they somehow passed size checks.
        final isAdmin = className == 'boundary' ||
            typeName == 'administrative' ||
            typeName == 'city' ||
            typeName == 'town' ||
            typeName == 'state' ||
            typeName == 'county';
        if (isAdmin) continue;

        if (isCampusLike) {
          bestCampus ??= polygon;
        } else {
          bestAny ??= polygon;
        }
      }

      return bestCampus ?? bestAny;
    } catch (_) {
      return null;
    }
  }

  static String? _normalizeOsmType(dynamic raw) {
    final value = raw?.toString().trim().toUpperCase();
    if (value == null || value.isEmpty) return null;
    if (value == 'N' || value == 'NODE') return 'N';
    if (value == 'W' || value == 'WAY') return 'W';
    if (value == 'R' || value == 'RELATION') return 'R';
    return null;
  }

  static String _photonDisplayName(Map properties) {
    final name = properties['name']?.toString().trim();
    final parts = <String>[
      if (name != null && name.isNotEmpty) name,
      for (final key in ['city', 'state', 'country'])
        if ((properties[key]?.toString().trim().isNotEmpty ?? false))
          properties[key].toString().trim(),
    ];

    if (parts.isNotEmpty) return parts.join(', ');

    return properties['street']?.toString().trim() ?? '';
  }

  void dispose() {
    _client.close();
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';

/// A place returned from OpenStreetMap Nominatim search.
class PlaceResult {
  const PlaceResult({
    required this.displayName,
    required this.position,
    this.type,
  });

  final String displayName;
  final LatLng position;
  final String? type;
}

/// Free geocoding via [Nominatim](https://nominatim.openstreetmap.org).
///
/// No API key. Please keep a clear User-Agent and avoid rapid-fire requests
/// (Nominatim usage policy).
class PlaceSearch {
  PlaceSearch({
    http.Client? client,
    this.userAgent = 'TeamMapFlutter/1.0 (team project; contact@example.com)',
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String userAgent;

  static const _endpoint = 'https://nominatim.openstreetmap.org/search';

  Future<List<PlaceResult>> search(
    String query, {
    int limit = 6,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final uri = Uri.parse(_endpoint).replace(
      queryParameters: {
        'q': trimmed,
        'format': 'json',
        'addressdetails': '0',
        'limit': '$limit',
      },
    );

    final response = await _client.get(
      uri,
      headers: {
        'User-Agent': userAgent,
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Search failed (${response.statusCode})');
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
          return PlaceResult(
            displayName: name,
            position: LatLng(lat, lon),
            type: raw['type']?.toString(),
          );
        })
        .whereType<PlaceResult>()
        .toList(growable: false);
  }

  void dispose() {
    _client.close();
  }
}

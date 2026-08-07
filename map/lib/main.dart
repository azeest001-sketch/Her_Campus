import 'package:flutter/material.dart';
import 'package:team_map/map_kit/map_kit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TeamMapApp());
}

class TeamMapApp extends StatelessWidget {
  const TeamMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Team Map — OpenFreeMap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B6E4F),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const MapDemoPage(),
    );
  }
}

/// Demo screen showing how teammates can use [TeamMap].
class MapDemoPage extends StatefulWidget {
  const MapDemoPage({super.key});

  @override
  State<MapDemoPage> createState() => _MapDemoPageState();
}

class _MapDemoPageState extends State<MapDemoPage> {
  TeamMapController? _map;
  final _search = PlaceSearch();
  var _is3d = false;
  var _toggling3d = false;
  String? _status;

  static const _demoCenter = LatLng(28.6139, 77.2090);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TeamMap(
        config: const MapConfig(
          style: OpenFreeMapStyle.liberty,
          initialCenter: _demoCenter,
          initialZoom: 13,
          enable3dOnStart: false,
        ),
        onReady: _onMapReady,
        overlayBuilder: (context, controller) {
          return Stack(
            children: [
              Positioned(
                top: MediaQuery.paddingOf(context).top + 12,
                left: 12,
                right: 12,
                child: _TopBar(
                  is3d: _is3d,
                  toggling3d: _toggling3d,
                  status: _status,
                  onSearch: () => _openSearch(controller),
                  onToggle3d: () => _toggle3d(controller),
                ),
              ),
              Positioned(
                right: 12,
                bottom: MediaQuery.paddingOf(context).bottom + 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'zoom_in',
                      tooltip: 'Zoom in',
                      onPressed: () => controller.zoomBy(1),
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'zoom_out',
                      tooltip: 'Zoom out',
                      onPressed: () => controller.zoomBy(-1),
                      child: const Icon(Icons.remove),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.extended(
                      heroTag: 'sample_route',
                      onPressed: _addSampleRoute,
                      icon: const Icon(Icons.route),
                      label: const Text('Sample route'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggle3d(TeamMapController controller) async {
    if (_toggling3d) return;
    setState(() {
      _toggling3d = true;
      _status = _is3d ? 'Leaving 3D…' : 'Entering 3D…';
    });
    try {
      await controller.toggle3d();
      if (!mounted) return;
      setState(() {
        _is3d = controller.is3dEnabled;
        _status = _is3d
            ? '3D on — pinch/drag to look around buildings'
            : '3D off';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _is3d = controller.is3dEnabled;
        _status = '3D failed: $e';
      });
    } finally {
      if (mounted) setState(() => _toggling3d = false);
    }
  }

  Future<void> _openSearch(TeamMapController controller) async {
    final result = await showModalBottomSheet<PlaceResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _PlaceSearchSheet(search: _search);
      },
    );
    if (result == null || !mounted) return;

    await controller.flyTo(
      result.position,
      zoom: 15.5,
      tilt: _is3d ? 55 : 0,
    );
    await controller.addMarker(
      MapMarkerData(
        id: 'search_result',
        position: result.position,
        title: result.displayName.split(',').first,
        iconColor: '#C62828',
      ),
    );
    setState(() => _status = result.displayName);
  }

  Future<void> _onMapReady(TeamMapController controller) async {
    _map = controller;
    _is3d = controller.is3dEnabled;

    controller.onMapTapped = (pos) {
      setState(() {
        _status =
            'Tapped ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      });
    };

    controller.onMapLongPressed = (pos) async {
      final id = 'pin_${DateTime.now().millisecondsSinceEpoch}';
      await controller.addMarker(
        MapMarkerData(
          id: id,
          position: pos,
          title: 'Dropped pin',
          iconColor: '#C62828',
        ),
      );
      setState(() => _status = 'Long-press pin added');
    };

    controller.onMarkerTapped = (marker) {
      setState(() => _status = 'Marker: ${marker.title ?? marker.id}');
    };

    await _seedDemoContent(controller);
    if (!mounted) return;
    setState(() => _status = 'Map ready — search or long-press to drop a pin');
  }

  Future<void> _seedDemoContent(TeamMapController controller) async {
    await controller.addMarkers([
      const MapMarkerData(
        id: 'india_gate',
        position: LatLng(28.6129, 77.2295),
        title: 'India Gate',
        iconColor: '#0B6E4F',
      ),
      const MapMarkerData(
        id: 'lotus_temple',
        position: LatLng(28.5535, 77.2588),
        title: 'Lotus Temple',
        iconColor: '#1565C0',
      ),
    ]);
  }

  Future<void> _addSampleRoute() async {
    final map = _map;
    if (map == null) return;

    const points = [
      LatLng(28.6129, 77.2295),
      LatLng(28.6200, 77.2400),
      LatLng(28.5535, 77.2588),
    ];

    await map.addPolyline(
      id: 'demo_route',
      points: points,
      color: '#0B6E4F',
      width: 5,
    );

    await map.fitBounds(
      LatLngBounds(
        southwest: const LatLng(28.55, 77.22),
        northeast: const LatLng(28.63, 77.27),
      ),
    );

    setState(() => _status = 'Sample route drawn');
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.is3d,
    required this.toggling3d,
    required this.status,
    required this.onSearch,
    required this.onToggle3d,
  });

  final bool is3d;
  final bool toggling3d;
  final String? status;
  final VoidCallback onSearch;
  final VoidCallback onToggle3d;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      color: scheme.surface.withValues(alpha: 0.94),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.map_outlined, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Team Map · Liberty',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: 'Search places',
                  onPressed: onSearch,
                  icon: const Icon(Icons.search),
                ),
                FilterChip(
                  selected: is3d,
                  label: Text(toggling3d ? '…' : (is3d ? '3D on' : '3D')),
                  avatar: toggling3d
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          is3d ? Icons.view_in_ar : Icons.view_in_ar_outlined,
                          size: 18,
                        ),
                  onSelected: toggling3d ? null : (_) => onToggle3d(),
                ),
              ],
            ),
            if (status != null) ...[
              const SizedBox(height: 6),
              Text(
                status!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlaceSearchSheet extends StatefulWidget {
  const _PlaceSearchSheet({required this.search});

  final PlaceSearch search;

  @override
  State<_PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<_PlaceSearchSheet> {
  final _controller = TextEditingController();
  var _loading = false;
  String? _error;
  List<PlaceResult> _results = const [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch([String? value]) async {
    final query = (value ?? _controller.text).trim();
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await widget.search.search(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
        if (results.isEmpty) {
          _error = 'No places found';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Search failed. Check your connection.';
        _results = const [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.55,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search city, street, landmark…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      tooltip: 'Search',
                      onPressed: _runSearch,
                      icon: const Icon(Icons.arrow_forward),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: _runSearch,
                ),
              ),
              if (_loading) const LinearProgressIndicator(minHeight: 2),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error!),
                ),
              Expanded(
                child: ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final place = _results[index];
                    return ListTile(
                      leading: const Icon(Icons.place_outlined),
                      title: Text(
                        place.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: place.type == null ? null : Text(place.type!),
                      onTap: () => Navigator.pop(context, place),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

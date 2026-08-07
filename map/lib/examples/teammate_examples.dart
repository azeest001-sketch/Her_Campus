/// Example snippets teammates can copy into their own screens.
///
/// These are documentation examples — the live demo lives in `lib/main.dart`.
library;

import 'package:flutter/material.dart';
import 'package:team_map/map_kit/map_kit.dart';

/// Minimal embed: just the map.
class MinimalMapExample extends StatelessWidget {
  const MinimalMapExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const TeamMap(
      config: MapConfig(
        style: OpenFreeMapStyle.liberty,
        initialCenter: LatLng(19.0760, 72.8777), // Mumbai
        initialZoom: 12,
      ),
    );
  }
}

/// Teammate A: delivery / routes.
class RoutesExample extends StatelessWidget {
  const RoutesExample({super.key});

  @override
  Widget build(BuildContext context) {
    return TeamMap(
      config: const MapConfig(initialZoom: 13),
      onReady: (map) async {
        await map.addMarker(
          const MapMarkerData(
            id: 'warehouse',
            position: LatLng(28.61, 77.20),
            title: 'Warehouse',
          ),
        );
        await map.addMarker(
          const MapMarkerData(
            id: 'customer',
            position: LatLng(28.63, 77.22),
            title: 'Customer',
          ),
        );
        await map.addPolyline(
          id: 'delivery',
          points: const [
            LatLng(28.61, 77.20),
            LatLng(28.62, 77.21),
            LatLng(28.63, 77.22),
          ],
        );
      },
    );
  }
}

/// Teammate B: places / zones + 3D preview.
class PlacesExample extends StatelessWidget {
  const PlacesExample({super.key});

  @override
  Widget build(BuildContext context) {
    return TeamMap(
      config: const MapConfig(
        enable3dOnStart: true,
        initialZoom: 16,
        initialCenter: LatLng(28.6139, 77.2090),
      ),
      onReady: (map) async {
        await map.addPolygon(
          id: 'campus',
          outline: const [
            LatLng(28.6120, 77.2070),
            LatLng(28.6120, 77.2110),
            LatLng(28.6160, 77.2110),
            LatLng(28.6160, 77.2070),
            LatLng(28.6120, 77.2070),
          ],
        );
        map.onMapTapped = (pos) {
          debugPrint('User tapped $pos');
        };
      },
    );
  }
}

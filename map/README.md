# Team Map (OpenFreeMap + Flutter)

Shared, free, detailed vector map your teammates can drop into their Flutter screens and extend.

- **Tiles:** [OpenFreeMap](https://openfreemap.org) — free public instance, **no API key**, OpenStreetMap data
- **Engine:** [maplibre_gl](https://pub.dev/packages/maplibre_gl)
- **Detail:** vector tiles — streets, buildings, POIs sharpen as you zoom
- **3D:** tilt + extruded buildings (built into Liberty)

## Quick start

```bash
flutter pub get
flutter run          # device / emulator
flutter run -d chrome
```

## Use it in your feature (for teammates)

```dart
import 'package:team_map/map_kit/map_kit.dart';

class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TeamMap(
      config: const MapConfig(
        style: OpenFreeMapStyle.liberty,
        initialCenter: LatLng(28.6139, 77.2090),
        initialZoom: 13,
      ),
      onReady: (map) async {
        await map.addMarker(
          const MapMarkerData(
            id: 'hq',
            position: LatLng(28.6139, 77.2090),
            title: 'HQ',
          ),
        );

        map.onMapTapped = (pos) {
          // your logic
        };

        // Optional 3D buildings view
        // await map.enable3d();
      },
    );
  }
}
```

Copy-paste samples also live in `lib/examples/teammate_examples.dart`.

## What you can add

| Need | API |
|------|-----|
| Markers / pins | `addMarker` / `addMarkers` / `removeMarker` |
| Search places | `PlaceSearch().search('Delhi')` then `flyTo` |
| Routes | `addPolyline` |
| Zones / areas | `addPolygon` |
| 3D buildings | `enable3d()` / `disable3d()` / `toggle3d()` |
| Camera | `flyTo`, `zoomBy`, `fitBounds` |
| Style | Always Liberty (`OpenFreeMapStyle.liberty`) |
| Custom marker images | `addImage(name, bytes)` then use that name as `iconImage` |
| Anything MapLibre supports | `map.raw` → underlying `MapLibreMapController` |

## Style (fixed for Her Campus)

| Style | Notes |
|-------|--------|
| **Liberty** only (`OpenFreeMapStyle.liberty`) | Street map + built-in 3D buildings |

Use the **3D** control (`enable3d()` / `toggle3d()`) to tilt and show buildings.

## Project layout

```
lib/
  main.dart                 # interactive demo (styles, 3D, sample route)
  map_kit/                  # ← share this module with teammates
    map_kit.dart            # barrel export
    team_map_controller.dart
    widgets/team_map.dart
    models/
    open_free_map_styles.dart
  examples/teammate_examples.dart
```

## Sharing with two teammates

1. Share this whole Flutter project (zip / git).
2. They run `flutter pub get` then `flutter run`.
3. For their own apps, either:
   - **Keep working in this repo** and add screens under `lib/`, or
   - **Copy `lib/map_kit/`** into their app and add `maplibre_gl` to their `pubspec.yaml`, plus the platform bits below.

### Platform bits (if copying into another app)

**Android** — internet (+ location if needed) in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

**iOS** — location keys in `Info.plist` if you enable `myLocationEnabled`.

**Web** — in `web/index.html` `<head>`:

```html
<script src="https://unpkg.com/maplibre-gl@^5.24.0/dist/maplibre-gl.js"></script>
<link href="https://unpkg.com/maplibre-gl@^5.24.0/dist/maplibre-gl.css" rel="stylesheet" />
```

## Attribution

OpenFreeMap / OpenStreetMap attribution is shown automatically by MapLibre. Keep it visible.

## Demo controls

- **3D** chip — tilt + buildings (zoom in near a city for best effect)
- Long-press map — drop a pin
- **Sample route** — polyline between demo markers

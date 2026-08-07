/// Shared OpenFreeMap + MapLibre kit for the team project.
///
/// Import this file in your feature screens:
/// ```dart
/// import 'package:team_map/map_kit/map_kit.dart';
/// ```
library;

export 'package:maplibre_gl/maplibre_gl.dart'
    show
        CameraPosition,
        CameraUpdate,
        LatLng,
        LatLngBounds,
        LineOptions,
        FillOptions,
        SymbolOptions,
        MapLibreMapController,
        MinMaxZoomPreference;

export 'models/map_config.dart';
export 'models/map_marker_data.dart';
export 'open_free_map_styles.dart';
export 'place_search.dart';
export 'team_map_controller.dart';
export 'widgets/team_map.dart';

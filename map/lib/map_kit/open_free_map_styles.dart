/// Free vector map style from [OpenFreeMap](https://openfreemap.org).
///
/// Her Campus uses **Liberty only** (street map + built-in 3D buildings).
/// No API key required on the public instance.
enum OpenFreeMapStyle {
  /// Full street map with labels, POIs, and built-in 3D buildings.
  liberty('https://tiles.openfreemap.org/styles/liberty', 'Liberty');

  const OpenFreeMapStyle(this.url, this.label);

  final String url;
  final String label;

  /// Liberty ships with a `building-3d` fill-extrusion layer.
  bool get hasBuiltIn3dBuildings => true;
}

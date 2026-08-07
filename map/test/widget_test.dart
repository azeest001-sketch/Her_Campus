import 'package:flutter_test/flutter_test.dart';
import 'package:team_map/map_kit/open_free_map_styles.dart';

void main() {
  test('OpenFreeMap styles expose https tile URLs', () {
    for (final style in OpenFreeMapStyle.values) {
      expect(style.url, startsWith('https://tiles.openfreemap.org/styles/'));
    }
    expect(OpenFreeMapStyle.liberty.hasBuiltIn3dBuildings, isTrue);
  });
}

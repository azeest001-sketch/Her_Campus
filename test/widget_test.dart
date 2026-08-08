import 'package:flutter_test/flutter_test.dart';
import 'package:her_campus/main.dart';

void main() {
  testWidgets('App shows role select', (tester) async {
    await tester.pumpWidget(const HerCampusApp());
    await tester.pump();
    expect(find.textContaining('HER CAMPUS'), findsOneWidget);
    expect(find.text('ADMIN'), findsOneWidget);
    expect(find.text('STUDENT'), findsOneWidget);
  });
}

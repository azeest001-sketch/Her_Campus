import 'package:flutter_test/flutter_test.dart';
import 'package:safe_campus/app/app.dart';

void main() {
  testWidgets('Mode select shows student and admin', (tester) async {
    await tester.pumpWidget(const SafeCampusApp());
    expect(find.text('Student mode'), findsOneWidget);
    expect(find.text('Admin mode'), findsOneWidget);
  });
}

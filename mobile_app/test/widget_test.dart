import 'package:flutter_test/flutter_test.dart';
import 'package:sih_inspector_app/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DrishtiApp());
    expect(find.text('DRISHTI'), findsOneWidget);
  });
}

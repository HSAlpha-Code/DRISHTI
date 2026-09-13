import 'package:flutter_test/flutter_test.dart';
import 'package:sih_inspector_app/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SihInspectorApp());
    expect(find.text('MoSJE Field Inspector'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:t3laly_admin/main.dart';

void main() {
  testWidgets('Admin app launches and shows the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const T3LalyAdminApp());
    await tester.pump();

    expect(find.text('T3LALY'), findsOneWidget);
  });
}

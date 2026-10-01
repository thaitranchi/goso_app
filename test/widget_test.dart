import 'package:flutter_test/flutter_test.dart';
import 'package:goso_app/main.dart';

void main() {
  testWidgets('Hiển thị màn hình chính', (WidgetTester tester) async {
    await tester.pumpWidget(const GoSoApp());
    await tester.pump();

    expect(find.text('GỗSổ'), findsOneWidget);
    expect(find.text('Tính m³'), findsOneWidget);
    expect(find.text('Khách hàng'), findsOneWidget);
  });
}

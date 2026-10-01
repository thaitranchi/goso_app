import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goso_app/views/calculator_screen.dart';

void main() {
  Finder inTab(String tab, String label) => find.descendant(
    of: find.byKey(Key(tab)),
    matching: find.widgetWithText(TextField, label),
  );

  testWidgets('Hai tab dùng controller riêng, nhập số không bị lẫn', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CalculatorScreen()));
    // Màn hình cao để ListView dựng hết, không bị lazy build ẩn kết quả.
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();

    // Tab "Gỗ tròn": nhập trước, rồi mới chuyển tab.
    await tester.enterText(inTab('tab-tron', 'Đường kính (cm)'), '20');
    await tester.enterText(inTab('tab-tron', 'Chiều dài (m)'), '4');
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('tab-tron')),
        matching: find.widgetWithText(FilledButton, 'Tính m³'),
      ),
    );
    await tester.pump();
    // π × (20/200)² × 4 = 0,126 m³
    expect(find.text('TỔNG: 0,126 m³'), findsOneWidget);

    await tester.tap(find.text('Gỗ xẻ / phôi'));
    await tester.pumpAndSettle();

    // Chiều dài ở tab xẻ phải trống, không dùng lại giá trị của tab tròn.
    expect(find.text('4'), findsNothing);

    await tester.enterText(inTab('tab-xa', 'Dày (cm)'), '2');
    await tester.enterText(inTab('tab-xa', 'Rộng (cm)'), '10');
    await tester.enterText(inTab('tab-xa', 'Chiều dài (m)'), '5');
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('tab-xa')),
        matching: find.widgetWithText(FilledButton, 'Tính m³'),
      ),
    );
    await tester.pump();

    // (2/100) × (10/100) × 5 = 0,010 m³
    expect(find.text('TỔNG: 0,010 m³'), findsOneWidget);
  });
}

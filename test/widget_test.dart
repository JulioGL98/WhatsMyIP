import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatsmyip/main.dart';
import 'package:whatsmyip/services/ip_fetcher.dart';

void main() {
  testWidgets('NotificationDialogScreen displays IP and Aceptar button', (WidgetTester tester) async {
    const testResult = IpResult(
      ip: '79.156.172.100',
      updatedAt: '2026-09-30 09:51:28',
      isSuccess: true,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: NotificationDialogScreen(
          autoFetch: false,
          initialResult: testResult,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('WhatsMyIP'), findsOneWidget);
    expect(find.text('79.156.172.100'), findsOneWidget);
    expect(find.byKey(const Key('btn_aceptar')), findsOneWidget);
  });
}

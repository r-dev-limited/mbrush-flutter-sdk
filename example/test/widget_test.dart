// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:mbrush_printer_plugin_example/main.dart';

void main() {
  testWidgets('plugin example smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('mbrush Printer Plugin Example'), findsOneWidget);
    expect(find.text('Printer Host'), findsOneWidget);
    expect(find.text('Text'), findsOneWidget);
  });
}

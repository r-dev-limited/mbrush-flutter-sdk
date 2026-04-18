// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mbrush_flutter_sdk/mbrush_flutter_sdk.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('estimate text to strips', (WidgetTester tester) async {
    const MidwifePrinter printer = MidwifePrinter();
    final PrintLayoutConfig cfg = PrintLayoutConfig.fromUserControls(
      fontHeightMm: 3.2,
      textWidthCm: 8.0,
    );
    final PrintEstimate estimate = printer.estimate(
      text: 'hello world ' * 40,
      config: cfg,
    );
    expect(estimate.strips.isNotEmpty, true);
  });
}

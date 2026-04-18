import 'package:flutter_test/flutter_test.dart';
import 'package:mbrush_flutter_sdk/mbrush_flutter_sdk.dart';

void main() {
  test('estimate splits long text into strips', () {
    const MidwifePrinter printer = MidwifePrinter();
    final PrintLayoutConfig cfg = PrintLayoutConfig.fromUserControls(
      fontHeightMm: 3.2,
      textWidthCm: 4.0,
    );
    final String text = List<String>.filled(120, 'hello world').join(' ');
    final PrintEstimate estimate = printer.estimate(text: text, config: cfg);

    expect(estimate.wrappedLines.isNotEmpty, true);
    expect(estimate.strips.isNotEmpty, true);
    expect(estimate.linesPerStrip > 0, true);
  });
}

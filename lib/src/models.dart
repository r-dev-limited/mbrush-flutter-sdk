import 'dart:math' as math;

class MidwifePrinterDefaults {
  static const double nozzleHeightMm = 14.2875;
  static const int dpiStep = 2; // 1200x600
  static const int stripHeightPx = 684;
  static const int marginLeftPx = 24;
  static const int marginRightPx = 24;
  static const int marginTopPx = 16;
  static const int marginBottomPx = 16;
  static const double lineHeightMultiplier = 1.25;
}

class PrintLayoutConfig {
  const PrintLayoutConfig({
    required this.fontSizePx,
    required this.lineHeightMultiplier,
    required this.stripWidth,
    required this.stripHeight,
    required this.marginLeft,
    required this.marginRight,
    required this.marginTop,
    required this.marginBottom,
  });

  factory PrintLayoutConfig.fromUserControls({
    required double fontHeightMm,
    required double textWidthCm,
    int dpiStep = MidwifePrinterDefaults.dpiStep,
    int stripHeightPx = MidwifePrinterDefaults.stripHeightPx,
    int marginLeftPx = MidwifePrinterDefaults.marginLeftPx,
    int marginRightPx = MidwifePrinterDefaults.marginRightPx,
    int marginTopPx = MidwifePrinterDefaults.marginTopPx,
    int marginBottomPx = MidwifePrinterDefaults.marginBottomPx,
    double lineHeightMultiplier = MidwifePrinterDefaults.lineHeightMultiplier,
  }) {
    final double pxPerMmY = stripHeightPx / MidwifePrinterDefaults.nozzleHeightMm;
    final double pxPerMmX = (1200.0 / dpiStep) / 25.4;
    final double fontPx = fontHeightMm * pxPerMmY;
    final int contentWidthPx = math.max(1, (textWidthCm * 10 * pxPerMmX).round());
    final int stripWidthPx = contentWidthPx + marginLeftPx + marginRightPx;
    return PrintLayoutConfig(
      fontSizePx: fontPx,
      lineHeightMultiplier: lineHeightMultiplier,
      stripWidth: stripWidthPx,
      stripHeight: stripHeightPx,
      marginLeft: marginLeftPx,
      marginRight: marginRightPx,
      marginTop: marginTopPx,
      marginBottom: marginBottomPx,
    );
  }

  final double fontSizePx;
  final double lineHeightMultiplier;
  final int stripWidth;
  final int stripHeight;
  final int marginLeft;
  final int marginRight;
  final int marginTop;
  final int marginBottom;

  double get contentWidth => math.max(1, stripWidth - marginLeft - marginRight).toDouble();
  double get contentHeight => math.max(1, stripHeight - marginTop - marginBottom).toDouble();

  int get linesPerStrip {
    final int lines = (contentHeight / (fontSizePx * lineHeightMultiplier)).floor();
    return math.max(1, lines);
  }
}

class PrintEstimate {
  const PrintEstimate({
    required this.wrappedLines,
    required this.linesPerStrip,
    required this.strips,
  });

  final List<String> wrappedLines;
  final int linesPerStrip;
  final List<List<String>> strips;
}

class PrinterInfo {
  const PrinterInfo({
    required this.state,
    required this.battery,
    required this.version,
  });

  final String state;
  final String battery;
  final String version;

  static PrinterInfo fromInfoString(String raw) {
    final Map<String, String> kv = <String, String>{};
    for (final String seg in raw.split(',')) {
      final List<String> parts = seg.trim().split(':');
      if (parts.length >= 2) {
        final String k = parts.first.trim();
        final String v = parts.sublist(1).join(':').trim();
        kv[k] = v;
      }
    }
    return PrinterInfo(
      state: kv['st'] ?? '?',
      battery: kv['bat'] ?? '?',
      version: kv['v'] ?? '?',
    );
  }
}

class PrintOrientation {
  const PrintOrientation({
    this.reverseMovementDirection = true,
    this.unmirrorGlyphs = true,
    this.rotate180 = true,
  });

  final bool reverseMovementDirection;
  final bool unmirrorGlyphs;
  final bool rotate180;
}

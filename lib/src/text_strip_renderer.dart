import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'models.dart';

class TextStripRenderer {
  static Future<Uint8List> renderToRgbColumnMajor({
    required List<String> lines,
    required PrintLayoutConfig config,
    required PrintOrientation orientation,
  }) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        config.stripWidth.toDouble(),
        config.stripHeight.toDouble(),
      ),
      bgPaint,
    );

    final ui.ParagraphBuilder pb = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textDirection: TextDirection.ltr,
        fontSize: config.fontSizePx,
        height: config.lineHeightMultiplier,
      ),
    )..pushStyle(ui.TextStyle(color: Colors.black));
    pb.addText(lines.join('\n'));
    final ui.Paragraph paragraph = pb.build()
      ..layout(ui.ParagraphConstraints(width: config.contentWidth));
    canvas.drawParagraph(
      paragraph,
      Offset(config.marginLeft.toDouble(), config.marginTop.toDouble()),
    );

    final ui.Image image = await recorder.endRecording().toImage(
      config.stripWidth,
      config.stripHeight,
    );
    final ByteData? rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (rgba == null) {
      throw Exception('Failed to render strip image');
    }
    final Uint8List src = rgba.buffer.asUint8List();
    final int width = config.stripWidth;
    final int height = config.stripHeight;
    final Uint8List rgb = Uint8List(width * height * 3);
    int out = 0;
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        int sampleX = x;
        int sampleY = y;
        if (orientation.unmirrorGlyphs) {
          sampleX = width - 1 - sampleX;
        }
        if (orientation.rotate180) {
          sampleX = width - 1 - sampleX;
          sampleY = height - 1 - sampleY;
        }
        final int i = (sampleY * width + sampleX) * 4;
        rgb[out++] = src[i];
        rgb[out++] = src[i + 1];
        rgb[out++] = src[i + 2];
      }
    }
    return rgb;
  }
}

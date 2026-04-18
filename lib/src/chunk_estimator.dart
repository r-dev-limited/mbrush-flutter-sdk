import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'models.dart';

class ChunkEstimator {
  static PrintEstimate estimate({
    required String text,
    required PrintLayoutConfig config,
  }) {
    final TextStyle style = TextStyle(
      fontSize: config.fontSizePx,
      height: config.lineHeightMultiplier,
    );
    final List<String> wrappedLines = _wrapText(
      text: text,
      maxWidth: config.contentWidth,
      style: style,
    );
    final List<List<String>> strips = <List<String>>[];
    for (int i = 0; i < wrappedLines.length; i += config.linesPerStrip) {
      final int end = math.min(i + config.linesPerStrip, wrappedLines.length);
      strips.add(wrappedLines.sublist(i, end));
    }
    return PrintEstimate(
      wrappedLines: wrappedLines,
      linesPerStrip: config.linesPerStrip,
      strips: strips,
    );
  }

  static List<String> _wrapText({
    required String text,
    required double maxWidth,
    required TextStyle style,
  }) {
    if (text.trim().isEmpty) {
      return <String>[];
    }
    final List<String> output = <String>[];
    final List<String> paragraphs = text.replaceAll('\r\n', '\n').split('\n');

    for (final String paragraph in paragraphs) {
      if (paragraph.isEmpty) {
        output.add('');
        continue;
      }
      final List<String> words = paragraph.split(RegExp(r'\s+'));
      String line = '';
      for (final String word in words) {
        if (word.isEmpty) {
          continue;
        }
        final String candidate = line.isEmpty ? word : '$line $word';
        if (_fits(candidate, maxWidth, style)) {
          line = candidate;
          continue;
        }
        if (line.isNotEmpty) {
          output.add(line);
          line = '';
        }
        if (_fits(word, maxWidth, style)) {
          line = word;
          continue;
        }
        final List<String> broken = _breakWord(word, maxWidth, style);
        if (broken.isNotEmpty) {
          output.addAll(broken.take(broken.length - 1));
          line = broken.last;
        }
      }
      if (line.isNotEmpty) {
        output.add(line);
      }
    }
    return output;
  }

  static List<String> _breakWord(String word, double maxWidth, TextStyle style) {
    final List<String> lines = <String>[];
    String current = '';
    for (final String rune in word.split('')) {
      final String next = '$current$rune';
      if (_fits(next, maxWidth, style)) {
        current = next;
      } else {
        if (current.isNotEmpty) {
          lines.add(current);
        }
        current = rune;
      }
    }
    if (current.isNotEmpty) {
      lines.add(current);
    }
    return lines;
  }

  static bool _fits(String text, double maxWidth, TextStyle style) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: double.infinity);
    return painter.width <= maxWidth;
  }
}

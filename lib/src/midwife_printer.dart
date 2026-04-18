import 'dart:typed_data';

import 'chunk_estimator.dart';
import 'mbd_converter.dart';
import 'models.dart';
import 'printer_api_client.dart';
import 'text_strip_renderer.dart';

typedef UploadProgress = void Function(
  int stripIndex,
  int stripCount,
  int bytesSent,
  int bytesTotal,
);

class MidwifePrinter {
  const MidwifePrinter({
    this.dpiStep = MidwifePrinterDefaults.dpiStep,
    this.cOrder = 0,
    this.cWidth = 0,
  });

  final int dpiStep;
  final int cOrder;
  final int cWidth;

  PrintEstimate estimate({
    required String text,
    required PrintLayoutConfig config,
  }) {
    return ChunkEstimator.estimate(text: text, config: config);
  }

  Future<List<Uint8List>> buildMbdStrips({
    required PrintEstimate estimate,
    required PrintLayoutConfig config,
    required PrintOrientation orientation,
  }) async {
    final MbdConverter converter = const MbdConverter();
    final List<Uint8List> strips = <Uint8List>[];
    for (int i = 0; i < estimate.strips.length; i++) {
      final Uint8List rgb = await TextStripRenderer.renderToRgbColumnMajor(
        lines: estimate.strips[i],
        config: config,
        orientation: orientation,
      );
      final Uint8List mbd = converter.convert(
        rgbColumnMajor: rgb,
        invert: orientation.reverseMovementDirection ? 1 : 0,
        cOrder: cOrder,
        cWidth: cWidth,
        dpiStep: dpiStep,
      );
      strips.add(mbd);
    }
    return strips;
  }

  Future<void> uploadText({
    required String host,
    required String text,
    required PrintLayoutConfig config,
    required PrintOrientation orientation,
    UploadProgress? onProgress,
  }) async {
    final PrinterApiClient client = PrinterApiClient(host);
    final bool online = await client.ping();
    if (!online) {
      throw Exception('Printer unreachable at $host');
    }
    final PrintEstimate estimate = this.estimate(text: text, config: config);
    if (estimate.strips.isEmpty) {
      throw Exception('No printable text.');
    }
    final List<Uint8List> mbdStrips = await buildMbdStrips(
      estimate: estimate,
      config: config,
      orientation: orientation,
    );

    await client.rmUpload();
    for (int i = 0; i < mbdStrips.length; i++) {
      await client.uploadFileChunked(
        filename: '$i.mbd',
        data: mbdStrips[i],
        onProgress: (int sent, int total) {
          onProgress?.call(i + 1, mbdStrips.length, sent, total);
        },
      );
    }
    await client.sync();
  }
}

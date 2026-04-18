import 'dart:convert';
import 'dart:typed_data';

class MbdConverter {
  const MbdConverter();

  static const List<List<int>> _orderTb = <List<int>>[
    <int>[7, 5, 3, 1, 8, 6, 4, 2, 0],
    <int>[2, 0, 7, 5, 3, 1, 8, 6, 4],
    <int>[3, 1, 8, 6, 4, 2, 0, 7, 5],
  ];

  static const List<int> _cShiftMd = <int>[20, 22, 0, 2];
  static const List<int> _mShiftMd = <int>[58, 56, 78, 76];
  static const List<int> _yShiftMd = <int>[114, 112, 134, 132];
  static const int _shiftMaxMd = 134;

  static const List<int> _cShiftOld = <int>[20, 22, 0, 2];
  static const List<int> _mShiftOld = <int>[66, 64, 86, 84];
  static const List<int> _yShiftOld = <int>[130, 128, 150, 148];
  static const int _shiftMaxOld = 150;

  Uint8List convert({
    required Uint8List rgbColumnMajor,
    required int invert,
    required int cOrder,
    required int cWidth,
    required int dpiStep,
    int stripHeight = 684,
  }) {
    final int imgWidth = rgbColumnMajor.length ~/ (3 * stripHeight);
    if (imgWidth <= 0 || rgbColumnMajor.length != imgWidth * 3 * stripHeight) {
      throw Exception('Invalid rgb column-major input size');
    }

    final bool isOld = cWidth == 1;
    final bool isCym = cOrder == 1;
    final List<int> cShift = List<int>.filled(4, 0);
    final List<int> mShift = List<int>.filled(4, 0);
    final List<int> yShift = List<int>.filled(4, 0);
    int shiftMax = 0;
    for (int i = 0; i < 4; i++) {
      cShift[i] = (isOld ? _cShiftOld[i] : _cShiftMd[i]) ~/ dpiStep;
      mShift[i] = (isOld ? _mShiftOld[i] : _mShiftMd[i]) ~/ dpiStep;
      yShift[i] = (isOld ? _yShiftOld[i] : _yShiftMd[i]) ~/ dpiStep;
    }
    shiftMax = (isOld ? _shiftMaxOld : _shiftMaxMd) ~/ dpiStep;

    final List<Uint8List> chC = List<Uint8List>.generate(
      4,
      (_) => Uint8List(imgWidth * 180),
    );
    final List<Uint8List> chM = List<Uint8List>.generate(
      4,
      (_) => Uint8List(imgWidth * 180),
    );
    final List<Uint8List> chY = List<Uint8List>.generate(
      4,
      (_) => Uint8List(imgWidth * 180),
    );

    for (int l = 0; l < imgWidth; l++) {
      final int colBase = l * 3 * stripHeight;
      for (int p = 4; p <= 170; p++) {
        for (int i = 0; i < 4; i++) {
          final int pixel = p * 4 + i;
          final int src = colBase + pixel * 3;
          final int r = rgbColumnMajor[src];
          final int g = rgbColumnMajor[src + 1];
          final int b = rgbColumnMajor[src + 2];
          final int dst = l * 180 + p;
          chC[i][dst] = r < 0x80 ? 1 : 0;
          if (isCym) {
            chY[i][dst] = g < 0x80 ? 1 : 0;
            chM[i][dst] = b < 0x80 ? 1 : 0;
          } else {
            chM[i][dst] = g < 0x80 ? 1 : 0;
            chY[i][dst] = b < 0x80 ? 1 : 0;
          }
        }
      }
    }

    final List<Uint8List> reC = List<Uint8List>.generate(
      4,
      (_) => Uint8List(imgWidth * 36),
    );
    final List<Uint8List> reM = List<Uint8List>.generate(
      4,
      (_) => Uint8List(imgWidth * 36),
    );
    final List<Uint8List> reY = List<Uint8List>.generate(
      4,
      (_) => Uint8List(imgWidth * 36),
    );

    for (int i = 0; i < 4; i++) {
      int orderC = 0;
      int orderM = 0;
      int orderY = 0;
      switch (i) {
        case 0:
          orderC = 0;
          orderM = 1;
          orderY = 1;
          break;
        case 1:
          orderC = 0;
          orderM = 2;
          orderY = 2;
          break;
        case 2:
          orderC = 2;
          orderM = 0;
          orderY = 0;
          break;
        case 3:
          orderC = 1;
          orderM = 0;
          orderY = 0;
          break;
      }
      for (int j = 0; j < imgWidth; j++) {
        _reorder(
          out: reC[i],
          outOffset: 36 * j,
          chLine: chC[i],
          chOffset: 180 * j,
          order: orderC,
        );
        _reorder(
          out: reM[i],
          outOffset: 36 * j,
          chLine: chM[i],
          chOffset: 180 * j,
          order: orderM,
        );
        _reorder(
          out: reY[i],
          outOffset: 36 * j,
          chLine: chY[i],
          chOffset: 180 * j,
          order: orderY,
        );
      }
    }

    final BytesBuilder out = BytesBuilder(copy: false);
    final Uint8List header = Uint8List(16);
    header.setAll(0, ascii.encode('MBrush'));
    header[7] = 0;
    header[8] = invert;
    header[9] = dpiStep;
    out.add(header);

    final Uint8List out5b = Uint8List(36 * 12);

    for (int l = 0; l < imgWidth + shiftMax; l++) {
      int p = 0;
      for (int i = 0; i < 36; i += 2) {
        out5b[p++] = _saveByte(reY[0], imgWidth, l, i, yShift[0]);
        out5b[p++] = _saveByte(reY[3], imgWidth, l, i, yShift[3]);
        out5b[p++] = _saveByte(reY[0], imgWidth, l, i + 1, yShift[0]);
        out5b[p++] = _saveByte(reY[3], imgWidth, l, i + 1, yShift[3]);
        out5b[p++] = _saveByte(reM[3], imgWidth, l, i, mShift[3]);
        out5b[p++] = _saveByte(reM[0], imgWidth, l, i, mShift[0]);
        out5b[p++] = _saveByte(reM[3], imgWidth, l, i + 1, mShift[3]);
        out5b[p++] = _saveByte(reM[0], imgWidth, l, i + 1, mShift[0]);
        out5b[p++] = _saveByte(reC[3], imgWidth, l, i, cShift[3]);
        out5b[p++] = _saveByte(reC[0], imgWidth, l, i, cShift[0]);
        out5b[p++] = _saveByte(reC[3], imgWidth, l, i + 1, cShift[3]);
        out5b[p++] = _saveByte(reC[0], imgWidth, l, i + 1, cShift[0]);
      }
      for (int i = 0; i < 36; i += 2) {
        out5b[p++] = _saveByte(reY[1], imgWidth, l, i, yShift[1]);
        out5b[p++] = _saveByte(reY[2], imgWidth, l, i, yShift[2]);
        out5b[p++] = _saveByte(reY[1], imgWidth, l, i + 1, yShift[1]);
        out5b[p++] = _saveByte(reY[2], imgWidth, l, i + 1, yShift[2]);
        out5b[p++] = _saveByte(reM[2], imgWidth, l, i, mShift[2]);
        out5b[p++] = _saveByte(reM[1], imgWidth, l, i, mShift[1]);
        out5b[p++] = _saveByte(reM[2], imgWidth, l, i + 1, mShift[2]);
        out5b[p++] = _saveByte(reM[1], imgWidth, l, i + 1, mShift[1]);
        out5b[p++] = _saveByte(reC[2], imgWidth, l, i, cShift[2]);
        out5b[p++] = _saveByte(reC[1], imgWidth, l, i, cShift[1]);
        out5b[p++] = _saveByte(reC[2], imgWidth, l, i + 1, cShift[2]);
        out5b[p++] = _saveByte(reC[1], imgWidth, l, i + 1, cShift[1]);
      }

      out.add(const <int>[0x00, 0x87]);

      final Uint8List packed = Uint8List((36 * 12 ~/ 8) * 5);
      int w = 0;
      for (int i = 0; i < 36 * 12; i += 8) {
        final int b0 = out5b[i];
        final int b1 = out5b[i + 1];
        final int b2 = out5b[i + 2];
        final int b3 = out5b[i + 3];
        final int b4 = out5b[i + 4];
        final int b5 = out5b[i + 5];
        final int b6 = out5b[i + 6];
        final int b7 = out5b[i + 7];
        packed[w++] = (b0 | (b1 << 5)) & 0xff;
        packed[w++] = ((b1 >> 3) | (b2 << 2) | (b3 << 7)) & 0xff;
        packed[w++] = ((b3 >> 1) | (b4 << 4)) & 0xff;
        packed[w++] = ((b4 >> 4) | (b5 << 1) | (b6 << 6)) & 0xff;
        packed[w++] = ((b6 >> 2) | (b7 << 3)) & 0xff;
      }
      out.add(packed);
    }

    return out.toBytes();
  }

  void _reorder({
    required Uint8List out,
    required int outOffset,
    required Uint8List chLine,
    required int chOffset,
    required int order,
  }) {
    final List<int> p = List<int>.generate(20, (int i) => chOffset + i * 9);
    int w = outOffset;
    for (int n = 0; n < 9; n++) {
      final int i = _orderTb[order][n];
      out[w++] = chLine[p[0] + i] |
          (chLine[p[2] + i] << 1) |
          (chLine[p[4] + i] << 2) |
          (chLine[p[6] + i] << 3) |
          (chLine[p[8] + i] << 4);
      out[w++] = chLine[p[1] + i] |
          (chLine[p[3] + i] << 1) |
          (chLine[p[5] + i] << 2) |
          (chLine[p[7] + i] << 3) |
          (chLine[p[9] + i] << 4);
      out[w++] = chLine[p[10] + i] |
          (chLine[p[12] + i] << 1) |
          (chLine[p[14] + i] << 2) |
          (chLine[p[16] + i] << 3) |
          (chLine[p[18] + i] << 4);
      out[w++] = chLine[p[11] + i] |
          (chLine[p[13] + i] << 1) |
          (chLine[p[15] + i] << 2) |
          (chLine[p[17] + i] << 3) |
          (chLine[p[19] + i] << 4);
    }
  }

  int _saveByte(
    Uint8List buf,
    int imgWidth,
    int l,
    int i,
    int shift,
  ) {
    final int srcLine = l - shift;
    if (srcLine < 0 || srcLine >= imgWidth) {
      return 0;
    }
    return buf[srcLine * 36 + i];
  }
}

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'models.dart';

class PrinterApiClient {
  PrinterApiClient(this.host);

  final String host;

  Uri _cmdUri(String cmd) => Uri.http(
        host,
        '/cgi-bin/cmd',
        <String, String>{'cmd': cmd},
      );

  Future<bool> ping() async {
    if (host.isEmpty) {
      return false;
    }
    final Uri uri = _cmdUri('get_info');
    try {
      final http.Response response = await http.get(uri).timeout(
        const Duration(seconds: 3),
      );
      if (response.statusCode != 200) {
        return false;
      }
      return response.body.contains('"info"');
    } catch (_) {
      return false;
    }
  }

  Future<PrinterInfo?> getInfo() async {
    if (host.isEmpty) {
      return null;
    }
    final Uri uri = _cmdUri('get_info');
    try {
      final http.Response response = await http.get(uri).timeout(
        const Duration(seconds: 3),
      );
      if (response.statusCode != 200) {
        return null;
      }
      final Object? decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final String? infoStr = decoded['info'] as String?;
      if (infoStr == null || !infoStr.startsWith('mb:')) {
        return null;
      }
      return PrinterInfo.fromInfoString(infoStr);
    } catch (_) {
      return null;
    }
  }

  Future<void> rmUpload() async {
    await _checkOk(_cmdUri('rm_upload'));
  }

  Future<void> sync() async {
    await _checkOk(_cmdUri('sync'));
  }

  Future<void> _checkOk(Uri uri) async {
    final http.Response response = await http.get(uri).timeout(
      const Duration(seconds: 5),
    );
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode} for $uri');
    }
    final Object? decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['status'] != 'ok') {
      throw Exception('Printer returned error for $uri: ${response.body}');
    }
  }

  Future<void> uploadFileChunked({
    required String filename,
    required Uint8List data,
    void Function(int sent, int total)? onProgress,
  }) async {
    const int chunkSize = 128 * 1024;
    int pos = 0;
    while (pos < data.length) {
      final int end = math.min(pos + chunkSize, data.length);
      final Uint8List chunk = data.sublist(pos, end);
      final Uri uri = Uri.http(host, '/cgi-bin/upload');
      final http.MultipartRequest request = http.MultipartRequest('POST', uri)
        ..fields['pos'] = '$pos'
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            chunk,
            filename: filename,
          ),
        );
      final http.StreamedResponse streamed = await request.send().timeout(
        const Duration(seconds: 20),
      );
      final String body = await streamed.stream.bytesToString();
      if (streamed.statusCode != 200) {
        throw Exception('Upload failed: HTTP ${streamed.statusCode}');
      }
      final Object? decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic> || decoded['status'] != 'ok') {
        throw Exception('Upload failed: $body');
      }
      pos = end;
      onProgress?.call(pos, data.length);
    }
  }
}

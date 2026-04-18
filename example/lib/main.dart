import 'package:flutter/material.dart';
import 'package:mbrush_flutter_sdk/mbrush_flutter_sdk.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mbrush Printer Plugin Example',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  final TextEditingController _hostController = TextEditingController(
    text: '192.168.88.1',
  );
  final TextEditingController _textController = TextEditingController();
  final MidwifePrinter _printer = const MidwifePrinter();

  double _fontHeightMm = 3.2;
  double _textWidthCm = 8.0;

  bool _reverseMovement = true;
  bool _unmirror = true;
  bool _rotate180 = true;

  bool _busy = false;
  String _status = 'Idle';
  PrintEstimate? _estimate;

  PrintLayoutConfig _layout() => PrintLayoutConfig.fromUserControls(
        fontHeightMm: _fontHeightMm,
        textWidthCm: _textWidthCm,
      );

  PrintOrientation _orientation() => PrintOrientation(
        reverseMovementDirection: _reverseMovement,
        unmirrorGlyphs: _unmirror,
        rotate180: _rotate180,
      );

  Future<void> _testConnection() async {
    setState(() => _status = 'Testing connection...');
    final PrinterInfo? info = await PrinterApiClient(_hostController.text.trim()).getInfo();
    if (!mounted) {
      return;
    }
    setState(() {
      if (info == null) {
        _status = 'Offline or unreachable';
      } else {
        _status = 'Connected: bat ${info.battery}%, st ${info.state}, fw ${info.version}';
      }
    });
  }

  void _estimateNow() {
    final PrintEstimate e = _printer.estimate(
      text: _textController.text,
      config: _layout(),
    );
    setState(() {
      _estimate = e;
      _status = 'Estimated ${e.strips.length} strips';
    });
  }

  Future<void> _printNow() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await _printer.uploadText(
        host: _hostController.text.trim(),
        text: _textController.text,
        config: _layout(),
        orientation: _orientation(),
        onProgress: (int i, int n, int sent, int total) {
          setState(() {
            _status = 'Uploading strip $i/$n (${((sent / total) * 100).toStringAsFixed(0)}%)';
          });
        },
      );
      setState(() => _status = 'Upload done. Ready to print on device.');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('mbrush Printer Plugin Example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          TextField(
            controller: _hostController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Printer Host',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            maxLines: 10,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Text',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _numberField(
                  label: 'Font H (mm)',
                  value: _fontHeightMm,
                  onChanged: (double v) => _fontHeightMm = v,
                  min: 1,
                  max: 8,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _numberField(
                  label: 'Text Width (cm)',
                  value: _textWidthCm,
                  onChanged: (double v) => _textWidthCm = v,
                  min: 2,
                  max: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            dense: true,
            value: _reverseMovement,
            onChanged: (bool? v) => setState(() => _reverseMovement = v ?? true),
            title: const Text('Reverse Movement Direction'),
          ),
          CheckboxListTile(
            dense: true,
            value: _unmirror,
            onChanged: (bool? v) => setState(() => _unmirror = v ?? true),
            title: const Text('Unmirror Glyphs'),
          ),
          CheckboxListTile(
            dense: true,
            value: _rotate180,
            onChanged: (bool? v) => setState(() => _rotate180 = v ?? true),
            title: const Text('Rotate 180°'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.tonal(
                onPressed: _busy ? null : _testConnection,
                child: const Text('Test Connection'),
              ),
              FilledButton.tonal(
                onPressed: _busy ? null : _estimateNow,
                child: const Text('Estimate'),
              ),
              FilledButton(
                onPressed: _busy ? null : _printNow,
                child: Text(_busy ? 'Working...' : 'Print'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Status: $_status'),
          const SizedBox(height: 8),
          if (_estimate != null) ...<Widget>[
            Text('Lines: ${_estimate!.wrappedLines.length}'),
            Text('Lines per strip: ${_estimate!.linesPerStrip}'),
            Text('Strips: ${_estimate!.strips.length}'),
          ],
        ],
      ),
    );
  }

  Widget _numberField({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required double min,
    required double max,
  }) {
    return TextFormField(
      initialValue: value.toStringAsFixed(2),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      onChanged: (String raw) {
        final double? parsed = double.tryParse(raw);
        if (parsed == null) {
          return;
        }
        onChanged(parsed.clamp(min, max));
      },
    );
  }
}

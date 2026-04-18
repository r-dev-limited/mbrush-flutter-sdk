# mbrush_flutter_sdk

Flutter plugin for text chunking, rendering, conversion to `.mbd`, and upload to mbrush-compatible printers over local HTTP (`192.168.88.1` by default over USB Ethernet).

Developed by `tomas.radvansky.org` at `rdev.co.nz`.

## Features

- Estimate required print strips from long text.
- Configure user-friendly print layout from:
  - font height (mm)
  - text width (cm)
- Render text strips to bitmap.
- Convert bitmap strips to `.mbd`.
- Upload strips using printer CGI API:
  - `/cgi-bin/cmd?cmd=rm_upload`
  - `/cgi-bin/upload`
  - `/cgi-bin/cmd?cmd=sync`

## Basic usage

```dart
import 'package:mbrush_flutter_sdk/mbrush_flutter_sdk.dart';

const MidwifePrinter printer = MidwifePrinter();

final layout = PrintLayoutConfig.fromUserControls(
  fontHeightMm: 3.2,
  textWidthCm: 8.0,
);

final orientation = PrintOrientation(
  reverseMovementDirection: true,
  unmirrorGlyphs: true,
  rotate180: true,
);

final estimate = printer.estimate(
  text: 'Long clinical note...',
  config: layout,
);

await printer.uploadText(
  host: '192.168.88.1',
  text: 'Long clinical note...',
  config: layout,
  orientation: orientation,
  onProgress: (stripIndex, stripCount, sent, total) {
    // update UI
  },
);
```

## Example app

A full example app is included in `example/` and uses this plugin as its only printer logic layer.

Run it:

```bash
cd example
flutter run
```

## iOS note

The example includes:

- `NSLocalNetworkUsageDescription`
- `NSAppTransportSecurity -> NSAllowsLocalNetworking = true`

to allow local HTTP printer access.

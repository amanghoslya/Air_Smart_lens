import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/models.dart';
import '../../state/app_scope.dart';
import '../../state/app_state.dart';
import '../parts.dart';
import '../shell.dart';
import '../theme.dart';
import '../widgets.dart';

// ---------------------------------------------------------------- Scan QR (30 Oct)
// Side menu › Scan QR. A QR code holds one lens, range and power (pair, right eye or left eye) as plain text
// (VOC1|…), so it is read against the catalogue on the phone and works offline. Scanning opens the product page with
// everything filled in; the customer types the quantity and taps Add to cart.
// The prototype has no camera, so it shows sample codes to tap; the app uses the phone's camera (mobile_scanner) and
// keeps the codes made on this phone and the samples below it, plus a field to type the code printed under a QR.

ScreenView scanScreen(BuildContext context, AppState s) {
  final mine = [
    for (final c in s.myQR)
      if (s.qrInfo(c) != null) s.qrInfo(c)!,
  ];
  final samples = [
    for (final c in s.data.scanSamples)
      if (s.qrInfo(c) != null) s.qrInfo(c)!,
  ];
  return ScreenView([
    const Hd('Scan QR', right: BagBtn()),
    const _Camera(),
    const Muted(
      'The lens, range and power open filled in. You only type the quantity. Reading the code works offline.',
      align: TextAlign.center,
      margin: EdgeInsets.only(top: 10),
    ),
    if (mine.isNotEmpty) ...[
      const Sec('QR codes you made · tap to open'),
      Gap([for (final i in mine) _CodeCard(i)]),
    ],
    const Sec('Sample codes · tap to open'),
    Gap([for (final i in samples) _CodeCard(i)]),
    const Muted('Make your own on the power screen of any lens: Make a QR code for this power.', margin: EdgeInsets.only(top: 10)),
    const Sec("QR won't read? Type the code under it"),
    const _TypeCode(),
  ], foot: s.cart.isNotEmpty ? Btn('Check out (${s.cart.length})', onTap: () => s.go('cart')) : null);
}

/// The camera, with the four corner marks of the prototype's `.qrcam` over it. A code is read once; the product
/// page then opens and this screen (and the camera) closes.
class _Camera extends StatefulWidget {
  const _Camera();
  @override
  State<_Camera> createState() => _CameraState();
}

class _CameraState extends State<_Camera> {
  // widget tests have no camera plugin
  static final bool _noCamera = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
  late final MobileScannerController _ctl = MobileScannerController(
    autoStart: !_noCamera,
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _done = false;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture cap) {
    if (_done) return;
    for (final b in cap.barcodes) {
      final v = b.rawValue;
      if (v == null || !v.startsWith('VOC1|')) continue;
      _done = AppScope.read(context).openScan(v);
      if (_done) _ctl.stop();
      return;
    }
    if (cap.barcodes.isNotEmpty) AppScope.read(context).toast('This QR code is not a Vishal lens code');
  }

  Widget _hint(BuildContext context, String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12.5, height: 1.4, color: Colors.white),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Camera. Point it at a lens QR code.',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 1,
          child: ColoredBox(
            color: const Color(0xFF15181E),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_noCamera)
                  _hint(context, 'Point the camera at a lens QR code: a printed label, or the back of a Vishal envelope')
                else
                  MobileScanner(
                    controller: _ctl,
                    onDetect: _onDetect,
                    errorBuilder: (context, e) => _hint(
                      context,
                      e.errorCode == MobileScannerErrorCode.permissionDenied
                          ? 'The camera is not allowed. Allow it in the phone settings, or type the code under the QR below.'
                          : 'The camera could not start. Type the code under the QR below.',
                    ),
                    placeholderBuilder: (context) => _hint(context, 'Point the camera at a lens QR code: a printed label, or the back of a Vishal envelope'),
                  ),
                const IgnorePointer(child: CustomPaint(painter: _Corners())),
                const Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: IgnorePointer(
                    child: Text(
                      'Point the camera at a lens QR code: a printed label, or the back of a Vishal envelope',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.white, shadows: [Shadow(blurRadius: 6)]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Corners extends CustomPainter {
  const _Corners();
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final m = size.width * .18, l = size.width * .12;
    final r = Rect.fromLTRB(m, m, size.width - m, size.height - m);
    for (final (o, dx, dy) in [(r.topLeft, 1.0, 1.0), (r.topRight, -1.0, 1.0), (r.bottomLeft, 1.0, -1.0), (r.bottomRight, -1.0, -1.0)]) {
      canvas.drawLine(o, o + Offset(dx * l, 0), p);
      canvas.drawLine(o, o + Offset(0, dy * l), p);
    }
  }

  @override
  bool shouldRepaint(_Corners old) => false;
}

/// `.env`: a code card, the QR on the left and the lens, range and power beside it. Tap to open it.
class _CodeCard extends StatelessWidget {
  final QrInfo i;
  const _CodeCard(this.i);
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = context.c;
    return Semantics(
      button: true,
      label: '${i.name}, ${i.pw.join(', ')}',
      child: Pressable(
        onTap: () => s.openScan(i.code),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14), boxShadow: c.e1),
          child: Row(
            children: [
              QrView(i.code, size: 76),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i.name,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${LensType.names[i.p.ptype]} · ${i.range}${i.p.ptype == LensType.prog && i.eye != 'P' ? ' · ${i.eyeTxt}' : ''}',
                      style: TextStyle(fontSize: 12, color: c.ink2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      i.pw.join(' · '),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.ink, fontFeatures: kTabular),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeCode extends StatefulWidget {
  const _TypeCode();
  @override
  State<_TypeCode> createState() => _TypeCodeState();
}

class _TypeCodeState extends State<_TypeCode> {
  final _t = TextEditingController();
  final _f = FocusNode();
  @override
  void dispose() {
    _t.dispose();
    _f.dispose();
    super.dispose();
  }

  void _open() {
    if (!AppScope.read(context).openScan(_t.text.trim())) _f.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _t,
            focusNode: _f,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _open(),
            style: TextStyle(fontSize: 14, color: c.ink, fontFeatures: kTabular),
            decoration: InputDecoration(
              hintText: 'VOC1|1|P|0|-2.50|-0.75|180|0.00',
              hintStyle: TextStyle(color: c.ink2),
              filled: true,
              fillColor: c.card,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.ink),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SBtn('Open', onTap: _open, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
      ],
    );
  }
}

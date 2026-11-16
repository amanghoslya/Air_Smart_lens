import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:qr/qr.dart';

/// A real, scannable QR (error correction M), as a grid of dark modules.
List<List<bool>> qrMatrix(String text) {
  final img = QrImage(QrCode.fromData(data: text, errorCorrectLevel: QrErrorCorrectLevel.M));
  final n = img.moduleCount;
  return [
    for (var y = 0; y < n; y++) [for (var x = 0; x < n; x++) img.isDark(y, x)],
  ];
}

/// What the label prints about the power (from `AppState.qrInfo`).
class LabelText {
  final String name; // "Air Smart Green 1.60 · Photo grey"
  final String typeAndRange; // "Single vision · −8.00−2.00"
  final String eyeTxt; // "Pair (same lens for either eye)"
  final List<String> pw; // one line per eye
  const LabelText({required this.name, required this.typeAndRange, required this.eyeTxt, required this.pw});
}

/// File name of a label: "QR Air Smart Green 1.60 -2.00 - -0.50.pdf".
String labelFileName(LabelText t) =>
    '${'QR ${t.name} ${t.pw.join(' ')}'.replaceAll('−', '-').replaceAll(RegExp(r'[^\w.+\- ]'), '').replaceAll(RegExp(r'\s+'), ' ').trim()}.pdf';

/// `labelPDF(code)`: an A6 counter card written by hand (30 Oct). The lens's envelope photo on a warm paper band at
/// the top, then the lens, range, eye and power, then the QR with how to use it beside it. Vector text and QR;
/// the photo is the JPEG itself ([envelopeJpeg], optional). Nothing is fetched.
Uint8List labelPdf(String code, LabelText t, {Uint8List? envelopeJpeg}) {
  const W = 298.0, H = 420.0;
  final m = qrMatrix(code), n = m.length;
  final j = envelopeJpeg != null ? _jpegSize(envelopeJpeg) : null;

  String asc(String s) => s.replaceAll('−', '-').replaceAll(RegExp(r'[^\x20-\x7E°·]'), '');
  String esc(String s) => asc(s).replaceAll(r'\', r'\\').replaceAll('(', r'\(').replaceAll(')', r'\)');
  String f1(num v) => v.toStringAsFixed(1);
  String f2(num v) => v.toStringAsFixed(2);
  String txt(num x, num y, num size, String s, [String font = 'F1']) => 'BT /$font ${_n(size)} Tf ${f1(x)} ${_n(y)} Td (${esc(s)}) Tj ET\n';
  int cw(String ch, bool bold) {
    if (RegExp(r'[0-9]').hasMatch(ch)) return 556;
    if (RegExp(r'[ .,·|:]').hasMatch(ch)) return 278;
    if (RegExp(r'[()]').hasMatch(ch)) return 333;
    if (ch == '+') return 584;
    if (ch == '-') return 333;
    if (ch == '/') return 278;
    if (RegExp(r'[A-Z]').hasMatch(ch)) return bold ? 722 : 667;
    if (RegExp(r'[il]').hasMatch(ch)) return bold ? 278 : 222;
    if (RegExp(r'[mw]').hasMatch(ch)) return bold ? 889 : 833;
    if (RegExp(r'[a-z]').hasMatch(ch)) return bold ? 580 : 530;
    return bold ? 600 : 556;
  }

  double wid(String s, num size, String font) => asc(s).split('').fold<int>(0, (a, ch) => a + cw(ch, font == 'F2')) * size / 1000;
  String ctr(num y, num size, String s, [String font = 'F1']) => txt(math.max(16, (W - wid(s, size, font)) / 2), y, size, s, font);
  String spaced(num y, num size, String s) => ctr(y, size, asc(s).split('').join(' '), 'F2');
  String rr(num x, num y, num w, num h, num r) {
    final k = r * 0.55;
    return '${_n(x + r)} ${_n(y)} m ${_n(x + w - r)} ${_n(y)} l ${_n(x + w - r + k)} ${_n(y)} ${_n(x + w)} ${_n(y + r - k)} ${_n(x + w)} ${_n(y + r)} c '
        '${_n(x + w)} ${_n(y + h - r)} l ${_n(x + w)} ${_n(y + h - r + k)} ${_n(x + w - r + k)} ${_n(y + h)} ${_n(x + w - r)} ${_n(y + h)} c '
        '${_n(x + r)} ${_n(y + h)} l ${_n(x + r - k)} ${_n(y + h)} ${_n(x)} ${_n(y + h - r + k)} ${_n(x)} ${_n(y + h - r)} c '
        '${_n(x)} ${_n(y + r)} l ${_n(x)} ${_n(y + r - k)} ${_n(x + r - k)} ${_n(y)} ${_n(x + r)} ${_n(y)} c h\n';
  }

  final c = StringBuffer();
  // card frame and paper band
  c.write('1 1 1 rg 0.86 0.84 0.80 RG 0.6 w ${rr(10, 10, W - 20, H - 20, 14)}B\n');
  const bandY = 250.0, bandH = 150.0;
  c.write('q ${rr(10, 10, W - 20, H - 20, 14)}W n 0.949 0.937 0.914 rg 10 ${_n(bandY)} ${_n(W - 20)} ${_n(bandH + 10)} re f Q\n');
  if (j != null) {
    const maxW = 150.0, maxH = 118.0;
    final sc = math.min(maxW / j.w, maxH / j.h), w = j.w * sc, h = j.h * sc, x = (W - w) / 2, y = bandY + (bandH - h) / 2 + 2;
    c.write('0.80 0.78 0.74 rg ${rr(x + 2, y - 4, w, h, 6)}f\n');
    c.write('q ${rr(x, y, w, h, 6)}W n ${f2(w)} 0 0 ${f2(h)} ${f2(x)} ${f2(y)} cm /Im1 Do Q\n');
  } else {
    c.write('0.11 0.13 0.19 rg ${ctr(bandY + 70, 22, t.name, 'F2')}');
  }
  const yTop = bandY - 22;
  c.write('0.60 0.61 0.64 rg ${spaced(yTop, 7, 'VISHAL OPTICAL CO.')}');
  c.write('0.11 0.13 0.19 rg ${ctr(yTop - 20, 15, t.name, 'F2')}');
  c.write('0.36 0.39 0.44 rg ${ctr(yTop - 35, 9, t.typeAndRange)}${ctr(yTop - 48, 9, t.eyeTxt)}');
  c.write('0.11 0.13 0.19 rg ');
  for (var i = 0; i < t.pw.length; i++) {
    c.write(ctr(yTop - 70 - i * 17, 15, t.pw[i], 'F2'));
  }
  // divider
  final dy = yTop - 84 - (t.pw.length - 1) * 17;
  c.write('0.89 0.87 0.84 RG 0.6 w 34 ${_n(dy)} m ${_n(W - 34)} ${_n(dy)} l S\n');
  // QR on the left, how to use on the right
  final qs = math.min(112.0, dy - 46), cell = qs / n, x0 = 30.0, y0 = dy - 12 - qs;
  c.write('0 0 0 rg\n');
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      if (m[y][x]) c.write('${f2(x0 + x * cell)} ${f2(y0 + qs - (y + 1) * cell)} ${f2(cell + 0.02)} ${f2(cell + 0.02)} re\n');
    }
  }
  c.write('f\n');
  final tx = x0 + qs + 18;
  c.write('0.11 0.13 0.19 rg ${txt(tx, y0 + qs - 12, 11, 'Scan to reorder', 'F2')}');
  const how = ['Air Smart Lens app', 'Menu > Scan QR', 'Enter the quantity', 'and add to cart.'];
  c.write('0.36 0.39 0.44 rg ${[for (var i = 0; i < how.length; i++) txt(tx, y0 + qs - 30 - i * 12, 8.5, how[i])].join()}');
  c.write('0.60 0.61 0.64 rg ${ctr(22, 6.5, code)}');

  // Latin-1 throughout, as the HTML app wrote the file byte by byte
  final content = latin1.encode(c.toString());
  final objs = <List<int>>[
    latin1.encode('<< /Type /Catalog /Pages 2 0 R >>'),
    latin1.encode('<< /Type /Pages /Kids [3 0 R] /Count 1 >>'),
    latin1.encode(
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ${_n(W)} ${_n(H)}] /Contents 4 0 R /Resources << /Font << /F1 5 0 R /F2 6 0 R >> ${j != null ? '/XObject << /Im1 7 0 R >> ' : ''}>> >>',
    ),
    [...latin1.encode('<< /Length ${content.length} >>\nstream\n'), ...content, ...latin1.encode('endstream')],
    latin1.encode('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>'),
    latin1.encode('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>'),
    if (j != null)
      [
        ...latin1.encode(
          '<< /Type /XObject /Subtype /Image /Width ${j.w} /Height ${j.h} /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length ${envelopeJpeg!.length} >>\nstream\n',
        ),
        ...envelopeJpeg,
        ...latin1.encode('\nendstream'),
      ],
  ];
  final out = BytesBuilder();
  out.add(latin1.encode('%PDF-1.4\n'));
  final off = <int>[];
  for (var i = 0; i < objs.length; i++) {
    off.add(out.length);
    out.add(latin1.encode('${i + 1} 0 obj\n'));
    out.add(objs[i]);
    out.add(latin1.encode('\nendobj\n'));
  }
  final xr = out.length;
  out.add(
    latin1.encode(
      'xref\n0 ${objs.length + 1}\n0000000000 65535 f \n${off.map((o) => '${o.toString().padLeft(10, '0')} 00000 n \n').join()}'
      'trailer\n<< /Size ${objs.length + 1} /Root 1 0 R >>\nstartxref\n$xr\n%%EOF',
    ),
  );
  return out.toBytes();
}

/// A number as JavaScript prints it (no trailing ".0").
String _n(num v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// Width and height of a baseline or progressive JPEG (its SOF marker).
({int w, int h})? _jpegSize(Uint8List b) {
  var i = 2;
  while (i + 8 < b.length) {
    if (b[i] != 0xFF) {
      i++;
      continue;
    }
    final m = b[i + 1], len = (b[i + 2] << 8) | b[i + 3];
    if (m >= 0xC0 && m <= 0xCF && m != 0xC4 && m != 0xC8 && m != 0xCC) {
      final h = (b[i + 5] << 8) | b[i + 6], w = (b[i + 7] << 8) | b[i + 8];
      return w > 0 && h > 0 ? (w: w, h: h) : null;
    }
    i += 2 + len;
  }
  return null;
}

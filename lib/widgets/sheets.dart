import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/Utils/format.dart';
import '../core/Data/Model/models.dart';
import '../core/Utils/quantity.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import 'theme.dart';
import 'widgets.dart';

/// A bottom sheet in the app's frosted style.
Future<T?> showAppSheet<T>(BuildContext context, WidgetBuilder builder) {
  final c = context.c;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: c.scrim.withValues(alpha: c.scrim.a * .7),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * .88),
            decoration: BoxDecoration(
              color: c.glass2,
              border: Border(top: BorderSide(color: c.glassEdge)),
            ),
            padding: EdgeInsets.fromLTRB(18, 10, 18, 18 + MediaQuery.paddingOf(ctx).bottom),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  AppScope(
                    state: AppScope.read(context),
                    child: Builder(builder: builder),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget sheetTitle(BuildContext context, String t) => Padding(
  padding: const EdgeInsets.only(bottom: 4),
  child: Text(
    t,
    style: TextStyle(fontFamily: kSerif, fontWeight: FontWeight.w600, fontSize: 24, color: context.c.ink),
  ),
);

Widget sheetFoot(List<Widget> buttons) => Padding(
  padding: const EdgeInsets.only(top: 16),
  child: Row(
    children: [
      for (var i = 0; i < buttons.length; i++) ...[if (i > 0) const SizedBox(width: 10), buttons[i]],
    ],
  ),
);

// ---------------------------------------------------------------- Type

/// Type: key in any value. The phone's number pad has no minus or plus key, so
/// the sign is chosen with − / + buttons outside the box (25 Oct); the box holds
/// only the number. It is rounded to the nearest 0.25.
void showTypeSheet(BuildContext context) {
  final s = AppScope.read(context);
  showAppSheet(context, (_) => _TypeSheet(s));
}

class _TypeSheet extends StatefulWidget {
  final AppState s;
  const _TypeSheet(this.s);
  @override
  State<_TypeSheet> createState() => _TypeSheetState();
}

class _TypeSheetState extends State<_TypeSheet> {
  late final cols = widget.s.rxCols.where((c) => !widget.s.fOff(c)).toList(); // nothing to type for a switched-off power
  late final Rx t = widget.s.padTarget;
  late final Map<String, int> sg = {
    for (final c in ['sph', 'cyl'])
      c: t.field(c) > 0
          ? 1
          : t.field(c) < 0
          ? -1
          : widget.s.pickSign.round(),
  };
  late final Map<String, TextEditingController> ctl = {
    for (final c in cols) c: TextEditingController(text: c == 'axis' ? '${t.axis}' : t.field(c).abs().toStringAsFixed(2)),
  };
  late final Map<String, FocusNode> fn = {
    for (final c in cols)
      c: FocusNode()
        ..addListener(() {
          final n = fn[c]!;
          if (n.hasFocus) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ctl[c]!.selection = TextSelection(baseOffset: 0, extentOffset: ctl[c]!.text.length);
            });
          }
        }),
  };

  @override
  void dispose() {
    for (final c in ctl.values) {
      c.dispose();
    }
    for (final f in fn.values) {
      f.dispose();
    }
    super.dispose();
  }

  String get _axisLab => widget.s.lens == LensType.kt ? 'Axis (45°, 90°, 135° or 180°)' : 'Axis (5° steps)';

  void _onInput(String c, String v) {
    if (c != 'sph' && c != 'cyl') return;
    int? sign;
    if (RegExp('[-−–]').hasMatch(v)) {
      sign = -1;
    } else if (v.contains('+')) {
      sign = 1;
    }
    if (sign == null) return;
    final clean = v.replaceAll(RegExp('[-−–+]'), '');
    ctl[c]!.value = TextEditingValue(
      text: clean,
      selection: TextSelection.collapsed(offset: clean.length),
    );
    setState(() => sg[c] = sign!);
  }

  void _done() {
    final out = <String, double>{};
    for (final c in cols) {
      final raw = ctl[c]!.text.replaceAll(RegExp('[−–]'), '-').replaceAll(RegExp(r'[\s+]'), '').replaceFirst(',', '.');
      final v = double.tryParse(raw);
      if (v == null || v.isNaN) continue;
      out[c] = v;
    }
    Navigator.of(context).pop();
    widget.s.applyTyped(out, sg);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final lab = {'sph': 'Sphere (SPH)', 'cyl': 'Cylinder (CYL)', 'axis': _axisLab, 'add': 'Addition (ADD)'};
    Widget signBtn(String f, int v) => Semantics(
      button: true,
      label: v < 0 ? 'Minus' : 'Plus',
      selected: sg[f] == v,
      child: GestureDetector(
        onTap: () {
          setState(() => sg[f] = v);
          fn[f]!.requestFocus();
        },
        child: Container(
          width: 40,
          height: 44,
          decoration: BoxDecoration(
            color: sg[f] == v ? c.navy : c.card2,
            border: Border.all(color: sg[f] == v ? c.navy : c.line),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            v < 0 ? minus : '+',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: sg[f] == v ? c.onNavy : c.ink2),
          ),
        ),
      ),
    );
    Widget row(String f) {
      final signed = f == 'sph' || f == 'cyl';
      return Row(
        children: [
          Expanded(
            child: Text(lab[f]!, style: TextStyle(fontSize: 14, color: c.ink)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 84,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (signed) ...[signBtn(f, -1), const SizedBox(width: 4), signBtn(f, 1)],
                if (f == 'add')
                  SizedBox(
                    width: 40,
                    height: 44,
                    child: Center(
                      child: Text(
                        '+',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c.ink2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
            child: TextField(
              controller: ctl[f],
              focusNode: fn[f],
              keyboardType: f == 'axis' ? TextInputType.number : const TextInputType.numberWithOptions(decimal: true),
              textInputAction: f == cols.last ? TextInputAction.done : TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,+\-−–]'))],
              onChanged: (v) => _onInput(f, v),
              onSubmitted: (_) => f == cols.last ? _done() : null,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.ink, fontFeatures: kTabular),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: c.card,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c.ink, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sheetTitle(context, widget.s.eyeLab),
        Muted(
          'Choose − or + first, then type the number from the slip. It is rounded to the nearest 0.25.'
          '${widget.s.lockInfo?.li != null ? ' A power outside this range moves to the nearest one in it.' : ''}',
          margin: const EdgeInsets.only(bottom: 12),
        ),
        Gap([for (final f in cols) row(f)]),
        sheetFoot([Btn('Cancel', ghost: true, onTap: () => Navigator.of(context).pop()), Btn('Done', onTap: _done)]),
      ],
    );
  }
}

// ---------------------------------------------------------------- Change quantity

void showQtySheet(BuildContext context, int i) {
  final s = AppScope.read(context);
  showAppSheet(context, (_) => _QtySheet(s, i));
}

class _QtySheet extends StatefulWidget {
  final AppState s;
  final int i;
  const _QtySheet(this.s, this.i);
  @override
  State<_QtySheet> createState() => _QtySheetState();
}

class _QtySheetState extends State<_QtySheet> {
  late final CartLine line = widget.s.cart[widget.i];
  late final String k = widget.s.product(line.pid!).ptype != LensType.prog
      ? 'H'
      : (line.qR != 0 && line.qL != 0
            ? 'P'
            : line.qR != 0
            ? 'R'
            : 'L');
  late double n = k == 'R'
      ? line.qR
      : k == 'L'
      ? line.qL
      : line.qty;

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sheetTitle(context, 'Change quantity'),
        Muted(shortName(s.product(line.pid!)), margin: const EdgeInsets.only(bottom: 8)),
        InfoBox(
          margin: EdgeInsets.zero,
          child: QtyCtl(kind: k, n: n, onStep: (d) => setState(() => n = qStepN(k, n, d))),
        ),
        sheetFoot([
          Btn('Cancel', ghost: true, onTap: () => Navigator.of(context).pop()),
          Btn(
            'Save',
            onTap: () {
              Navigator.of(context).pop();
              s.setLineQty(widget.i, k, n);
            },
          ),
        ]),
      ],
    );
  }
}

// ---------------------------------------------------------------- Pre-order

void showPreorderSheet(BuildContext context, int pid, int li) {
  final s = AppScope.read(context);
  showAppSheet(context, (_) => _PreorderSheet(s, pid, li));
}

class _PreorderSheet extends StatefulWidget {
  final AppState s;
  final int pid, li;
  const _PreorderSheet(this.s, this.pid, this.li);
  @override
  State<_PreorderSheet> createState() => _PreorderSheetState();
}

class _PreorderSheetState extends State<_PreorderSheet> {
  int q = 10;
  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final p = s.product(widget.pid);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sheetTitle(context, 'Pre-order'),
        Muted('${shortName(p)} · ${rg(p.lines[widget.li].range)}', margin: const EdgeInsets.only(bottom: 8)),
        InfoBox(
          margin: EdgeInsets.zero,
          child: QtyCtl(kind: 'P', n: q.toDouble(), label: 'Pairs', sub: '', onStep: (d) => setState(() => q = (q + d).clamp(1, 9999))),
        ),
        const Muted('Sent when the stock reaches the warehouse. You can cancel a pre-order until then.', margin: EdgeInsets.only(top: 12)),
        sheetFoot([
          Btn('Cancel', ghost: true, onTap: () => Navigator.of(context).pop()),
          Btn(
            'Pre-order $q pairs',
            onTap: () {
              Navigator.of(context).pop();
              s.placePreOrder(widget.pid, widget.li, q);
            },
          ),
        ]),
      ],
    );
  }
}

/// Confirmation popup dialog for signing out.
Future<bool?> showSignOutDialog(BuildContext context, AppState s) {
  final c = context.c;
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: c.paper,
        surfaceTintColor: Colors.transparent,
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: c.line),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFEF4444),
                size: 28,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              s.tr('Sign out'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: c.ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Are you sure you want to sign out?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                color: c.mute,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(color: c.line, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.transparent,
                    ),
                    child: Text(
                      'No',
                      style: TextStyle(
                        color: c.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, true);
                      s.signOut();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      backgroundColor: const Color(0xFFEF4444),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Yes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/models.dart';
import '../core/quantity.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import 'icons.dart';
import 'sheets.dart';
import 'theme.dart';
import 'widgets.dart';

const _ih = 34.0, _rows = 3; // 29 Oct: three rows (value above, chosen, value below) to save height
const fieldNames = {'sph': 'Sphere', 'cyl': 'Cylinder', 'axis': 'Axis', 'add': 'Addition'};
const fieldAbbr = {'sph': 'SPH', 'cyl': 'CYL', 'axis': 'AXIS', 'add': 'ADD'};

String wheelLabel(String f, double v) => f == 'axis' ? '${v.round()}°' : fmt(v);

/// `whVals(f)`: a wheel's values, plus powers on top. Inside a lens or range only the powers it is made in.
List<double> wheelValuesFor(AppState s, String f) {
  final lv = s.lockVals(f, s.padTarget);
  if (lv != null && lv.isNotEmpty) return (f == 'sph' || f == 'cyl') ? lv.reversed.toList() : lv;
  return wheelValues(f, s.lens);
}

/// The power input: scroll wheels as in the Hansco app (25 Oct). One wheel per field, side by side: SPH and CYL
/// for single vision; SPH, CYL, AXIS and ADD for KT and progressive. Each step clicks. Plus powers sit above 0.00
/// and minus powers below. Tapping a value moves to it; Type keys in any value.
/// Inside one range (29 Oct) a value that cannot change is shown fixed, not scrolled. SPH and CYL can be switched
/// off above their wheels (3 Nov): the wheel greys out (with AXIS for CYL) and the power is 0.
class PowerWheels extends StatelessWidget {
  const PowerWheels({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = context.c;
    final cols = s.rxCols;
    final t = s.padTarget;
    final pe = s.lens == LensType.prog ? s.peye : 'H';
    final eyeKey = s.eye == 'L' && s.rxL != null ? 'L' : 'R';
    Widget? leftBtn;
    if (s.rxMode && s.lens == LensType.prog && pe == 'P' && s.eye == 'R' && s.rxL == null) {
      leftBtn = _WideBtn('Left eye different ›', s.leftDifferent);
    } else if (s.rxMode && s.lens == LensType.prog && pe == 'P' && s.rxL != null) {
      leftBtn = _WideBtn(s.eye == 'L' ? '‹ Back to right eye' : 'Left eye ›', () => s.switchEye(s.eye == 'L' ? 'R' : 'L'));
    }
    final locked = s.lockInfo != null;
    Widget col(String f) {
      if (s.fOff(f)) return _FixedWheel(field: f, value: f == 'axis' ? '—' : '0.00', note: f == 'axis' ? 'No CYL' : 'Off', off: true, cols: cols);
      if (locked) {
        if (f == 'axis') {
          final fx = s.axisFixed(t);
          if (t.cyl == 0) return _FixedWheel(field: f, value: '—', note: 'No CYL', cols: cols);
          if (fx != null) return _FixedWheel(field: f, value: '$fx°', note: 'Fixed', cols: cols);
        } else {
          final lv = s.lockVals(f, t);
          if (lv != null && lv.length == 1) return _FixedWheel(field: f, value: wheelLabel(f, lv[0]), note: 'Fixed', cols: cols);
        }
      }
      final vals = wheelValuesFor(s, f);
      return PowerWheel(
        key: ValueKey('wheel-$f-$eyeKey-${s.lens}-${vals.length}-${vals.first}-${vals.last}'),
        field: f,
        eye: eyeKey,
        value: t.field(f),
        lensType: s.lens,
        vals: vals,
        label: WheelLabel(field: f, cols: cols),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.line),
        boxShadow: c.e1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: s.eyeLab,
                        style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
                      ),
                      if (s.lens == LensType.prog && pe == 'P' && s.rxL == null) TextSpan(text: s.rxMode ? ' · left eye the same' : ' · same power both eyes'),
                    ],
                  ),
                  style: TextStyle(fontSize: 12, color: c.ink2),
                ),
              ),
              const SoundToggle(),
              const SizedBox(width: 12),
              LinkBtn('Type', onTap: () => showTypeSheet(context)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < cols.length; i++) ...[if (i > 0) const SizedBox(width: 6), Expanded(child: col(cols[i]))],
            ],
          ),
          if (leftBtn != null) leftBtn,
        ],
      ),
    );
  }
}

/// `.wlab`: the field name above a wheel, with the on/off switch for SPH and CYL (3 Nov).
class WheelLabel extends StatelessWidget {
  final String field;
  final List<String> cols;
  const WheelLabel({super.key, required this.field, required this.cols});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = context.c;
    final tg = s.canTog(field, cols);
    final on = !s.fOff(field);
    final text = Text(
      fieldAbbr[field]!,
      style: TextStyle(fontSize: 10.5, letterSpacing: 1.47, fontWeight: FontWeight.w600, color: on ? c.mute : c.mute.withValues(alpha: .55)),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SizedBox(
        height: 17,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (tg) ...[
              Semantics(
                toggled: on,
                label: '${fieldNames[field]} ${on ? 'on' : 'off'}',
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => s.toggleField(field),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 26,
                      height: 15,
                      decoration: BoxDecoration(color: on ? c.ink : c.line, borderRadius: BorderRadius.circular(8)),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 180),
                        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          width: 11,
                          height: 11,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: c.card,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: c.shade, blurRadius: 2, offset: const Offset(0, 1))],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
            text,
          ],
        ),
      ),
    );
  }
}

/// `.wfix`: a value that cannot be scrolled (fixed inside a range, no cylinder, or switched off).
class _FixedWheel extends StatelessWidget {
  final String field, value, note;
  final bool off;
  final List<String> cols;
  const _FixedWheel({required this.field, required this.value, required this.note, required this.cols, this.off = false});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      children: [
        WheelLabel(field: field, cols: cols),
        Opacity(
          opacity: off ? .42 : 1,
          child: Container(
            height: _ih * _rows,
            decoration: BoxDecoration(color: c.card2, borderRadius: BorderRadius.circular(14)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 4,
                  right: 4,
                  top: (_ih * _rows - _ih) / 2,
                  height: _ih,
                  child: Container(
                    decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(10), boxShadow: c.e1),
                  ),
                ),
                Semantics(
                  label: '${fieldNames[field]} $value, ${note.toLowerCase()}',
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.ink, fontFeatures: kTabular),
                      ),
                      Text(
                        note.toUpperCase(),
                        style: TextStyle(fontSize: 9.5, letterSpacing: 1.1, fontWeight: FontWeight.w600, color: c.mute),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WideBtn extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _WideBtn(this.text, this.onTap);
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: c.card2,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
        ),
      ),
    );
  }
}

/// The speaker button: Sound and vibration on or off.
class SoundToggle extends StatelessWidget {
  const SoundToggle({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = context.c;
    return Semantics(
      button: true,
      toggled: s.fb,
      label: 'Sound and vibration',
      child: GestureDetector(
        onTap: s.toggleSound,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.card2,
            border: Border.all(color: s.fb ? c.ink : c.line),
          ),
          alignment: Alignment.center,
          child: SvgIcon(s.fb ? Ic.soundOn : Ic.soundOff, size: 17, color: s.fb ? c.ink : c.mute),
        ),
      ),
    );
  }
}

class PowerWheel extends StatefulWidget {
  final String field;
  final String eye;
  final double value;
  final String lensType;
  final List<double> vals;
  final Widget label;
  const PowerWheel({super.key, required this.field, required this.eye, required this.value, required this.lensType, required this.vals, required this.label});
  @override
  State<PowerWheel> createState() => _PowerWheelState();
}

class _PowerWheelState extends State<PowerWheel> {
  List<double> get vals => widget.vals;
  late FixedExtentScrollController _ctl;
  late int _last;
  Timer? _timer;
  bool _quiet = true;

  int _indexOf(double v) {
    var i = vals.indexWhere((x) => (x - v).abs() < 1e-6);
    if (i < 0) {
      i = 0;
      for (var k = 0; k < vals.length; k++) {
        if ((vals[k] - v).abs() < (vals[i] - v).abs()) i = k;
      }
    }
    return i;
  }

  @override
  void initState() {
    super.initState();
    _last = _indexOf(widget.value);
    _ctl = FixedExtentScrollController(initialItem: _last);
    WidgetsBinding.instance.addPostFrameCallback((_) => _quiet = false);
  }

  @override
  void didUpdateWidget(PowerWheel old) {
    super.didUpdateWidget(old);
    final i = _indexOf(widget.value);
    if (i != _last && (_timer == null || !_timer!.isActive)) {
      _quiet = true;
      _last = i;
      _ctl.jumpToItem(i);
      WidgetsBinding.instance.addPostFrameCallback((_) => _quiet = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctl.dispose();
    super.dispose();
  }

  void _changed(int i) {
    if (_quiet || i == _last) return;
    final s = AppScope.read(context);
    setState(() => _last = i);
    final v = vals[i];
    final f = widget.field;
    final mn = f == 'axis' ? vals.reduce(math.min) : 0.0;
    final mx = f == 'axis' ? vals.reduce(math.max) : math.max(vals.first.abs(), vals.last.abs());
    s.sound.tick(tickKind(f, f == 'axis' ? v : v.abs(), mn, mx, widget.lensType));
    s.wheelLive.value = (eye: widget.eye, f: f, v: v);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 160), _commit);
  }

  void _commit() {
    if (!mounted) return;
    final s = AppScope.read(context);
    s.wheelLive.value = null;
    s.setField(widget.field, vals[_last]);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      children: [
        widget.label,
        Container(
          height: _ih * _rows,
          decoration: BoxDecoration(color: c.card2, borderRadius: BorderRadius.circular(14)),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                left: 4,
                right: 4,
                top: (_ih * _rows - _ih) / 2,
                height: _ih,
                child: Container(
                  decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(10), boxShadow: c.e1),
                ),
              ),
              Positioned.fill(
                child: Semantics(
                  label: fieldNames[widget.field],
                  value: wheelLabel(widget.field, vals[_last]),
                  child: ListWheelScrollView.useDelegate(
                    controller: _ctl,
                    itemExtent: _ih,
                    diameterRatio: 1000,
                    perspective: 0.0001,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: _changed,
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: vals.length,
                      builder: (context, i) {
                        final on = i == _last;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _ctl.animateToItem(i, duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                          child: Center(
                            child: Text(
                              wheelLabel(widget.field, vals[i]),
                              style: TextStyle(
                                fontSize: on ? 17 : 15,
                                fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                                color: on ? c.ink : c.ink2,
                                fontFeatures: kTabular,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A value cell in the power table that follows the wheel while it turns.
class LiveCell extends StatelessWidget {
  final AppState s;
  final String eye, f;
  final double value;
  final bool on, same;
  const LiveCell({super.key, required this.s, required this.eye, required this.f, required this.value, required this.on, required this.same});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: () => s.tapCell(eye, f),
      child: ValueListenableBuilder(
        valueListenable: s.wheelLive,
        builder: (context, live, _) {
          final activeEye = s.eye == 'L' && s.rxL != null ? 'L' : 'R';
          final v = live != null && live.f == f && live.eye == eye && activeEye == eye ? live.v : value;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: on ? c.ink : c.line, width: on ? 2 : 1),
            ),
            alignment: Alignment.center,
            child: Text(
              wheelLabel(f, v),
              maxLines: 1,
              style: TextStyle(fontSize: 14.5, fontWeight: same ? FontWeight.w400 : FontWeight.w600, color: same ? c.mute : c.ink, fontFeatures: kTabular),
            ),
          );
        },
      ),
    );
  }
}

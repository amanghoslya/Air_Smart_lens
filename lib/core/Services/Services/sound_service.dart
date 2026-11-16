import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Clicks on the power wheels and the app's few sounds (add to cart, remove,
/// wishlist, shortfall, cancel, order placed), with haptics.
///
/// The HTML app synthesised these with Web Audio; here they are short WAV files
/// rendered from the same recipes (assets/sounds). All follow the Sound and
/// vibration switch.
class SoundService {
  bool enabled = true;
  final Map<String, List<AudioPlayer>> _pool = {};
  final Map<String, int> _next = {};
  DateTime _lastHaptic = DateTime.fromMillisecondsSinceEpoch(0);

  static const _files = ['tick_minor', 'tick_major', 'tick_edge', 'add', 'remove', 'heart_on', 'heart_off', 'warn', 'cancel', 'whoosh', 'thud', 'celebrate'];

  Future<void> init() async {
    try {
      await AudioPlayer.global.setAudioContext(AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers, respectSilence: true).build());
    } catch (_) {}
    for (final f in _files) {
      // Ticks can fire quickly on a fast flick, so they get a few players each.
      final n = f.startsWith('tick') ? 4 : 1;
      _pool[f] = [
        for (var i = 0; i < n; i++)
          AudioPlayer()
            ..setPlayerMode(PlayerMode.lowLatency)
            ..setReleaseMode(ReleaseMode.stop),
      ];
      for (final p in _pool[f]!) {
        unawaited(p.setSource(AssetSource('sounds/$f.wav')).catchError((_) {}));
      }
    }
  }

  void _play(String name) {
    if (!enabled) return;
    final players = _pool[name];
    if (players == null || players.isEmpty) return;
    final i = _next[name] ?? 0;
    _next[name] = (i + 1) % players.length;
    final p = players[i];
    unawaited(() async {
      try {
        await p.stop();
        await p.resume();
      } catch (_) {}
    }());
  }

  void _haptic(Future<void> Function() fn) {
    if (!enabled) return;
    final now = DateTime.now();
    if (now.difference(_lastHaptic).inMilliseconds < 28) return;
    _lastHaptic = now;
    unawaited(fn().catchError((_) {}));
  }

  /// One wheel step: 'minor', 'major' (whole powers) or 'edge' (ends of the range).
  void tick(String kind) {
    _play('tick_$kind');
    _haptic(
      kind == 'minor'
          ? HapticFeedback.selectionClick
          : kind == 'major'
          ? HapticFeedback.lightImpact
          : HapticFeedback.mediumImpact,
    );
  }

  void add() {
    _haptic(HapticFeedback.lightImpact);
    _play('add');
  }

  void remove() {
    _haptic(HapticFeedback.selectionClick);
    _play('remove');
  }

  void heart(bool on) {
    _haptic(HapticFeedback.lightImpact);
    _play(on ? 'heart_on' : 'heart_off');
  }

  void toggle() => tick('minor');

  void warn() {
    _haptic(HapticFeedback.mediumImpact);
    _play('warn');
  }

  void cancel() {
    _haptic(HapticFeedback.mediumImpact);
    _play('cancel');
  }

  void whoosh() => _play('whoosh');
  void thud() => _play('thud');

  void celebrate() {
    _play('celebrate');
    _haptic(HapticFeedback.heavyImpact);
  }

  void dispose() {
    for (final l in _pool.values) {
      for (final p in l) {
        unawaited(p.dispose());
      }
    }
  }
}

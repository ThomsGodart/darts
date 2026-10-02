import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen from sleeping while the scoreboard must stay visible.
abstract interface class ScreenAwake {
  Future<void> keepOn();
  Future<void> release();
}

class WakelockScreenAwake implements ScreenAwake {
  const WakelockScreenAwake();

  @override
  Future<void> keepOn() => _guard(WakelockPlus.enable);

  @override
  Future<void> release() => _guard(WakelockPlus.disable);

  /// A screen that sleeps is an annoyance, never a reason to crash.
  Future<void> _guard(Future<void> Function() call) async {
    try {
      await call();
    } catch (error) {
      debugPrint('Wakelock unavailable: $error');
    }
  }
}

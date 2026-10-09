import 'package:flutter/foundation.dart';

import 'fullscreen_platform.dart' as platform;

/// In-app fullscreen: the scoreboard fills the display without using the
/// browser's own chrome. Web uses the Fullscreen API; phones hide the
/// system bars.
class AppFullscreen extends ChangeNotifier {
  AppFullscreen({
    bool? supported,
    Future<void> Function()? enter,
    Future<void> Function()? exit,
    bool Function()? readActive,
    void Function(void Function(bool active) onChanged)? listen,
    void Function()? stopListening,
  }) : isSupported = supported ?? platform.fullscreenSupported,
       _enter = enter ?? platform.enterFullscreen,
       _exit = exit ?? platform.exitFullscreen,
       _readActive = readActive ?? (() => platform.fullscreenActive),
       _stopListening = stopListening ?? platform.stopListeningFullscreen {
    if (isSupported) {
      (listen ?? platform.listenFullscreen)(_sync);
      _active = _readActive();
    }
  }

  /// Whether this build can enter fullscreen from a button.
  final bool isSupported;

  final Future<void> Function() _enter;
  final Future<void> Function() _exit;
  final bool Function() _readActive;
  final void Function() _stopListening;

  var _active = false;

  /// Whether the display is currently fullscreen.
  bool get isActive => _active;

  Future<void> toggle() => _active ? exit() : enter();

  Future<void> enter() async {
    if (!isSupported || _active) return;
    try {
      await _enter();
      _active = true;
      notifyListeners();
    } catch (error) {
      debugPrint('Fullscreen unavailable: $error');
    }
  }

  Future<void> exit() async {
    if (!isSupported || !_active) return;
    try {
      await _exit();
      _active = false;
      notifyListeners();
    } catch (error) {
      debugPrint('Fullscreen exit failed: $error');
    }
  }

  /// The display left or entered fullscreen without the button, as with
  /// Escape in a browser.
  void _sync(bool active) {
    if (_active == active) return;
    _active = active;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }
}

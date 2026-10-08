import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Immersive system UI on phones and tablets; desktop windows need a
/// native plugin, so the in-app control stays off there.
bool get fullscreenSupported =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

bool get fullscreenActive => _active;

var _active = false;

Future<void> enterFullscreen() async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  _active = true;
}

Future<void> exitFullscreen() async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  _active = false;
}

void listenFullscreen(void Function(bool active) onChanged) {}

void stopListeningFullscreen() {}

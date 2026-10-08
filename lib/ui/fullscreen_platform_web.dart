import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Browser Fullscreen API, driven from the app — not the browser chrome.
bool get fullscreenSupported => true;

bool get fullscreenActive => web.document.fullscreenElement != null;

Future<void> enterFullscreen() async {
  final root = web.document.documentElement;
  if (root == null) return;
  await root.requestFullscreen().toDart;
}

Future<void> exitFullscreen() async {
  if (!fullscreenActive) return;
  await web.document.exitFullscreen().toDart;
}

web.EventListener? _listener;

void listenFullscreen(void Function(bool active) onChanged) {
  stopListeningFullscreen();
  _listener = (web.Event _) {
    onChanged(fullscreenActive);
  }.toJS;
  web.document.addEventListener('fullscreenchange', _listener!);
}

void stopListeningFullscreen() {
  final listener = _listener;
  if (listener == null) return;
  web.document.removeEventListener('fullscreenchange', listener);
  _listener = null;
}

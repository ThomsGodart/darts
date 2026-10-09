/// A platform with neither `dart:io` nor JS interop: nothing to drive.
bool get fullscreenSupported => false;

bool get fullscreenActive => false;

Future<void> enterFullscreen() async {}

Future<void> exitFullscreen() async {}

void listenFullscreen(void Function(bool active) onChanged) {}

void stopListeningFullscreen() {}

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

/// Optional Crashlytics (crashes only — no behavioural analytics).
///
/// Enabled in release when [DefaultFirebaseOptions.isConfigured] is true
/// (after `flutterfire configure` + `google-services.json`). Never throws:
/// the app stays local-first and must start offline.
Future<void> initCrashReporting({
  Future<void> Function()? initializer,
  bool? releaseOnly,
}) async {
  final inRelease = releaseOnly ?? kReleaseMode;
  if (!inRelease) {
    debugPrint('Crash reporting skipped: not a release build');
    return;
  }
  try {
    await (initializer ?? _initFirebaseCrashlytics)();
  } catch (error) {
    debugPrint('Crash reporting unavailable: $error');
  }
}

Future<void> _initFirebaseCrashlytics() async {
  if (!DefaultFirebaseOptions.isConfigured) {
    debugPrint('Crash reporting skipped: Firebase options not configured');
    return;
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Crashes only — do not log custom analytics events here.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

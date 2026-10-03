import 'package:firebase_core/firebase_core.dart';

/// Placeholder until `flutterfire configure` writes real options.
///
/// Keep [isConfigured] false so release builds stay offline-safe without
/// `google-services.json`. Replace this file with the FlutterFire output and
/// set [isConfigured] to true (or regenerate and flip the flag in one place).
class DefaultFirebaseOptions {
  /// True only when real Firebase project options are wired.
  static const isConfigured = false;

  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'DefaultFirebaseOptions are not configured. '
      'Run flutterfire configure and set isConfigured = true.',
    );
  }
}

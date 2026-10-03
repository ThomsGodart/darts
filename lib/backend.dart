import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Compile-time credentials for the optional cloud backend.
///
/// Pass with `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`.
/// Never ship a `.env` asset: the app is local-first and must build without one.
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

/// Initializes the optional cloud backend (Supabase).
///
/// Never throws: the app is local-first and must work offline, so missing
/// credentials or an unreachable backend is logged and ignored.
Future<void> initBackend({Future<void> Function()? initializer}) async {
  try {
    await (initializer ?? _initSupabase)();
  } catch (error) {
    debugPrint('Backend unavailable, running offline: $error');
  }
}

Future<void> _initSupabase() async {
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    debugPrint('Backend skipped: no SUPABASE_URL / SUPABASE_ANON_KEY defines');
    return;
  }
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseAnonKey,
  );
}

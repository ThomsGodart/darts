import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Initializes the optional cloud backend (Supabase).
///
/// Never throws: the app is local-first and must work offline, so a missing
/// `.env` or an unreachable backend is logged and ignored.
Future<void> initBackend({Future<void> Function()? initializer}) async {
  try {
    await (initializer ?? _initSupabase)();
  } catch (error) {
    debugPrint('Backend unavailable, running offline: $error');
  }
}

Future<void> _initSupabase() async {
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
}

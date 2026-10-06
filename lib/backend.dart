import 'share/share_transport.dart';
import 'share/supabase_share_transport.dart';

/// The Supabase project sessions are shared through. Both values are
/// public by design: the key only opens what the project leaves open to
/// anyone, here its Realtime broadcast. Another project is passed with
/// `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...`;
/// an empty value builds an app that cannot share.
const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://xpfqsrouluglhkdihmft.supabase.co',
);
const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: 'sb_publishable_3uJHivSjBOhLnw7iMk2_Gw_sct_29hN',
);

/// What sessions are shared over, or null in a build without a backend.
///
/// Making it does not touch the network: the app is local-first, and
/// only connects once a session is shared or joined.
ShareTransport? shareTransport({
  String url = supabaseUrl,
  String publishableKey = supabasePublishableKey,
}) => url.isEmpty || publishableKey.isEmpty
    ? null
    : SupabaseShareTransport(url, publishableKey);

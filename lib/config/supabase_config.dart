/// Supabase project settings. This is the only file to change when moving to another Supabase
/// project.
///
/// The anon key is safe to keep in source: it only has the `anon` role, and Row Level Security
/// blocks everything the policies don't allow.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://iliayouejnpkgicvudtv.supabase.co';

  static const String publishableKey = 'sb_publishable_ikWe3ZC9r7LgsY-WB83NJA_dgbWObj4';

  /// Where Supabase sends the browser after an email link (password reset, email change). This
  /// exact URL must also be in Supabase's Auth > URL Configuration > Redirect URLs list.
  ///
  /// Set up for Flutter Web (run with `--web-port=5000`). A mobile build would need a custom URL
  /// scheme here instead, plus the matching Android/iOS config.
  static const String authRedirectUrl = 'http://localhost:5000';
}

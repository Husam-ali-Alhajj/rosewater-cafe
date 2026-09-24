/// Points the app at a Supabase project.
///
/// This is the ONE file to edit when handing the project off to a different
/// Supabase project (e.g. the company's own, replacing this dev project).
/// Both values below are safe to keep in source: the anon key only ever
/// grants the `anon` role, and every table is locked down with Row Level
/// Security (see supabase/migrations/) — it cannot read or write anything
/// the RLS policies don't explicitly allow.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://iliayouejnpkgicvudtv.supabase.co';

  static const String publishableKey = 'sb_publishable_ikWe3ZC9r7LgsY-WB83NJA_dgbWObj4';

  /// Where Supabase sends the browser after a password-recovery email link
  /// is opened (`resetPasswordForEmail`'s `redirectTo`). This EXACT value
  /// must also be added to the Supabase dashboard's Auth -> URL
  /// Configuration -> Redirect URLs allow-list, or Supabase silently falls
  /// back to the project's default Site URL instead.
  ///
  /// Currently set up for Flutter Web only (decision #55): run with
  /// `flutter run -d chrome --web-port=5000` so this fixed port actually
  /// matches what's running. A real mobile build (Android/iOS) would need
  /// this changed to a custom URL scheme instead (e.g.
  /// `rosewatercafe://reset-password`), plus the matching platform config
  /// in AndroidManifest.xml / Info.plist -- not done yet, since testing so
  /// far has been web-only.
  static const String passwordRecoveryRedirectUrl = 'http://localhost:5000';
}

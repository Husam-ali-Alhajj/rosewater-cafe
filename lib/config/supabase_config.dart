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
}

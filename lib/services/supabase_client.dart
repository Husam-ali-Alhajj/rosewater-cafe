import 'package:supabase_flutter/supabase_flutter.dart';

/// Shared Supabase client, ready to use anywhere after [Supabase.initialize]
/// has run in main(). Import this file and call `supabase.from(...)`,
/// `supabase.auth...`, `supabase.storage...`, etc.
final SupabaseClient supabase = Supabase.instance.client;

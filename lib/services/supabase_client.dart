import 'package:supabase_flutter/supabase_flutter.dart';

/// The shared Supabase client, ready after Supabase.initialize() in main().
final SupabaseClient supabase = Supabase.instance.client;

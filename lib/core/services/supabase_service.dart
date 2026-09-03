import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

class SupabaseService {
  const SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    if (!AppConfig.hasSupabaseConfig) {
      throw StateError(
        'Missing Supabase configuration. Provide SUPABASE_URL and '
        'SUPABASE_ANON_KEY using --dart-define.',
      );
    }

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }
}

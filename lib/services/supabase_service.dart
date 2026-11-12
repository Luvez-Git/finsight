import 'package:supabase/supabase.dart';

class SupabaseService {
  SupabaseService._();

  static SupabaseClient? _client;

  static SupabaseClient get client {
    final value = _client;
    if (value == null) {
      throw StateError('Supabase has not been initialized.');
    }
    return value;
  }

  static void initialize() {
    const url = String.fromEnvironment('SUPABASE_URL');
    const key = String.fromEnvironment('SUPABASE_ANON_KEY');

    if (url.isEmpty || key.isEmpty) {
      throw StateError(
        'Missing SUPABASE_URL or SUPABASE_ANON_KEY. '
        'Run Flutter with --dart-define.',
      );
    }

    _client = SupabaseClient(url, key);
  }
}

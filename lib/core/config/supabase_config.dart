class SupabaseConfig {
  static const String url =
      'https://dyrsrfzkpiqeiidmhhsq.supabase.co';

  static const String publishableKey =
      'sb_publishable_I6gu8pXOrMBxkS9-Zn4N9g_42ng4820';

  static bool get isConfigured {
    return url.isNotEmpty &&
        publishableKey.isNotEmpty &&
        !publishableKey.contains('PEGA_AQUI');
  }
}
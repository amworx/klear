/// Runtime configuration for Klear.
///
/// Sensitive values are injected at build/run time via `--dart-define`,
/// never stored in source. Example:
///   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///              --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
///
/// `SUPABASE_ANON_KEY` is accepted as a fallback name (legacy projects pass
/// the `anon` JWT there); prefer the publishable key for new integrations.
abstract final class AppConfig {
  static const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  // Publishable key (sb_publishable_...) is preferred; fall back to the JWT anon
  // key so projects configured with SUPABASE_ANON_KEY keep working.
  static const String _supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  static String get supabaseUrl => _supabaseUrl;
  static String get supabasePublishableKey => _supabasePublishableKey;

  /// Where Supabase sends users when they click a link in an auth email.
  /// Overridable for local/dev via --dart-define=SUPABASE_EMAIL_REDIRECT_URL.
  static const String emailRedirectUrl = String.fromEnvironment(
    'SUPABASE_EMAIL_REDIRECT_URL',
    defaultValue: 'https://klear.cc',
  );

  /// Whether Supabase credentials were provided.
  static bool get hasSupabaseConfig =>
      _supabaseUrl.isNotEmpty && _supabasePublishableKey.isNotEmpty;
}
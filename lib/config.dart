/// Valeurs passées au build avec --dart-define (voir README).
class Config {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const tmdbApiKey = String.fromEnvironment('TMDB_API_KEY');

  /// Deep link utilisé au retour de Spotify / X.
  static const authRedirect = 'io.supabase.cosmeros://login-callback/';
}

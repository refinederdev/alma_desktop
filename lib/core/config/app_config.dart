class AppConfig {
  static const String baseURL = "https://almacrm.com/api/";
  static int appVersion = 1;

  // Reverb Configuration
  static const String reverbAppKey = 'syrpsbslynsri6rjop2a'; // REVERB_APP_KEY
  static const String reverbHost = 'ws.almacrm.com'; // REVERB_HOST
  static const int reverbPort = 443; // REVERB_PORT
  static const String reverbScheme =
      'wss'; // REVERB_SCHEME (wss للاتصال الآمن بـ WebSocket)
  // Base URL بدون /api للـ broadcasting/auth
  static String get baseUrlWithoutApi => baseURL.replaceAll('/api/', '');
}

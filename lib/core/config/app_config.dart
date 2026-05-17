import 'package:alma_desktop/core/services/server_config_service/server_config_service.dart';

class AppConfig {
  static const String defaultBaseURL = 'https://almacrm.com/api/';

  static String _baseURL = defaultBaseURL;

  static String get baseURL => _baseURL;

  static int appVersion = 1;
  static const String appUpdatesBaseUrl = 'https://refineder.ai/alma-desktop';
  static const String githubRepoOwner = 'refinederdev';
  static const String githubRepoName = 'alma_desktop';
  static const String latestReleaseApi =
      'https://api.github.com/repos/$githubRepoOwner/$githubRepoName/releases/latest';

  // Reverb Configuration
  static const String reverbAppKey = 'syrpsbslynsri6rjop2a'; // REVERB_APP_KEY
  static const String reverbHost = 'ws.almacrm.com'; // REVERB_HOST
  static const int reverbPort = 443; // REVERB_PORT
  static const String reverbScheme =
      'wss'; // REVERB_SCHEME (wss للاتصال الآمن بـ WebSocket)

  static String get baseUrlWithoutApi {
    if (_baseURL.endsWith('/api/')) {
      return _baseURL.substring(0, _baseURL.length - 5);
    }
    if (_baseURL.endsWith('/api')) {
      return _baseURL.substring(0, _baseURL.length - 4);
    }
    return _baseURL;
  }

  static Future<void> init(ServerConfigService serverConfigService) async {
    final saved = serverConfigService.savedBaseUrl;
    if (saved != null && saved.isNotEmpty) {
      _baseURL = saved;
    } else {
      _baseURL = defaultBaseURL;
    }
  }

  static Future<void> applyBaseUrl(
    String url,
    ServerConfigService serverConfigService,
  ) async {
    final normalized = ServerConfigService.normalizeApiBaseUrl(url);
    await serverConfigService.saveBaseUrl(normalized);
    _baseURL = normalized;
  }

  static Future<void> resetBaseUrl(
    ServerConfigService serverConfigService,
  ) async {
    await serverConfigService.clearSavedBaseUrl();
    _baseURL = defaultBaseURL;
  }
}

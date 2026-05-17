import 'package:alma_desktop/core/services/local_storage_service/local_storage_service.dart';

class ServerConfigService {
  static const String storageKey = 'api_base_url_override';

  final LocalStorageService _storage;

  ServerConfigService(this._storage);

  String? get savedBaseUrl => _storage.getString(storageKey);

  Future<void> saveBaseUrl(String url) async {
    await _storage.setString(storageKey, normalizeApiBaseUrl(url));
  }

  Future<void> clearSavedBaseUrl() async {
    _storage.remove(storageKey);
  }

  static String normalizeApiBaseUrl(String input) {
    var url = input.trim();
    if (url.isEmpty) {
      throw const FormatException('empty_url');
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const FormatException('invalid_url');
    }

    var normalized = url;
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    if (normalized.endsWith('/api')) {
      return '$normalized/';
    }

    return '$normalized/api/';
  }
}

import 'package:shared_preferences/shared_preferences.dart';

import 'local_storage_service.dart';

class LocalStorageServiceSharedPreferencesImpl implements LocalStorageService {
  final SharedPreferences preferences;

  LocalStorageServiceSharedPreferencesImpl(this.preferences);
  @override
  bool? getBool(String key) {
    final bool? value = preferences.getBool(key);

    return value;
  }

  @override
  String? getString(String key) {
    return preferences.getString(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    await preferences.setString(key, value);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    await preferences.setBool(key, value);
  }

  @override
  void remove(String key) {
    preferences.remove(key);
  }
}

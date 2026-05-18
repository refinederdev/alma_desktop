import 'dart:async';

import 'package:alma_desktop/core/services/local_storage_service/local_storage_service.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/auth/domain/entities/user.dart';
import 'package:alma_desktop/features/calls/presentation/controllers/call_controller.dart';
import 'package:alma_desktop/features/global/domain/usecases/check_if_user_is_logged_in_use_case.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GlobalController extends GetxController {
  static GlobalController get to => Get.find();

  final CheckIfUserIsLoggedInUseCase checkIfUserIsLoggedInUseCase;

  GlobalController({required this.checkIfUserIsLoggedInUseCase});

  String? token;
  Locale currentLocale = Locale('ar', 'SA');
  ThemeMode themeMode = ThemeMode.system;
  User? user;

  Future<void> checkIfUserIsLoggedIn() async {
    final result = await checkIfUserIsLoggedInUseCase(NoParams());
    result.fold((failure) => Get.snackbar('Error', failure.message ?? ''), (
      checkAuth,
    ) async {
      token = checkAuth.accessToken;
      user = checkAuth.user;
      update();
      _bootstrapCallsModule();
    });
  }

  /// تهيئة وحدة المكالمات بعد توافر الـ token. آمنة للاستدعاء أكثر من مرة.
  void bootstrapCallsModule() {
    if (token == null || token!.isEmpty) return;
    try {
      final cc = Get.find<CallController>();
      // تهيئة كسولة — تجلب الجلسات وتفتح الـ Reverb للمكالمات.
      unawaited(cc.initialize());
    } catch (_) {
      // CallController قد لا يكون مسجّلاً بعد في حالات نادرة
    }
  }

  void _bootstrapCallsModule() => bootstrapCallsModule();

  void getLocale() {
    final locale = Get.find<LocalStorageService>().getString('locale');
    if (locale != null) {
      currentLocale = Locale(locale, 'SA');
    }
    update();
  }

  void getThemeMode() {
    final raw = Get.find<LocalStorageService>().getString('themeMode');
    themeMode = switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    update();
  }

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    final stored = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    Get.find<LocalStorageService>().setString('themeMode', stored);
    update();
  }

  void clearLogedIn() {
    token = null;
    Get.find<LocalStorageService>().remove("accessToken");
    Get.find<LocalStorageService>().remove("user");
    user = null;
    try {
      Get.find<CallController>().shutdown();
    } catch (_) {}
    update();
  }

  void changeLocale(Locale locale) {
    currentLocale = locale;
    Get.find<LocalStorageService>().setString('locale', locale.languageCode);
    Get.updateLocale(locale);
    update();
  }

  void setUser(User user) {
    this.user = user;
    update();
  }

  List<Locale> get supportedLocales => [Locale('ar', 'SA'), Locale('en', 'US')];

  @override
  void onInit() {
    super.onInit();
    // clearLogedIn();
    checkIfUserIsLoggedIn();
    getLocale();
    getThemeMode();
  }
}

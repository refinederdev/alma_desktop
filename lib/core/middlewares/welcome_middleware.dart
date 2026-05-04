import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/app_routes.dart';
import '../config/app_strings.dart';
import '../services/local_storage_service/local_storage_service.dart';

class WelcomeMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final localStorageService = Get.find<LocalStorageService>();
    final countryCode = localStorageService.getString(AppStrings.country);

    // If country is already selected, redirect to main screen
    if (countryCode != null) {
      return const RouteSettings(name: AppRoutes.main);
    }

    // Otherwise continue to welcome screen
    return null;
  }
}

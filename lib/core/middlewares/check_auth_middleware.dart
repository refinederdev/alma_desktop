import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/local_storage_service/local_storage_service.dart';
import '../config/app_routes.dart';

class CheckAuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final localStorageService = Get.find<LocalStorageService>();
    final token = localStorageService.getString('accessToken');

    // If token is available, user is authenticated, allow access to main screen
    if (token != null && token.isNotEmpty) {
      return null;
    }

    // Otherwise, redirect to login screen
    return const RouteSettings(name: AppRoutes.login);
  }
}

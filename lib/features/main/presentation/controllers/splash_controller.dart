import 'package:alma_desktop/core/config/app_routes.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class SplashController extends GetxController {
  static const Duration _displayDuration = Duration(milliseconds: 2400);

  @override
  void onReady() {
    super.onReady();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goToMainAfterSplash();
    });
  }

  Future<void> _goToMainAfterSplash() async {
    await Future<void>.delayed(_displayDuration);
    Get.offAllNamed(AppRoutes.main);
  }
}

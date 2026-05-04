import 'package:alma_desktop/core/config/app_routes.dart';
import 'package:alma_desktop/core/errors/app_messages.dart';
import 'package:alma_desktop/core/widgets/app_phone_input.dart';
import 'package:alma_desktop/features/auth/domain/usecases/login_use_case.dart';
import 'package:alma_desktop/features/global/presentation/controllers/global_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  final LoginUseCase loginUseCase;
  final GlobalController globalController;

  LoginController({required this.loginUseCase, required this.globalController});

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool isPasswordVisible = false;

  /// Desktop default: email. User can switch to phone (with country code).
  bool useEmailLogin = true;
  String selectedCountryCode = Country.kuwait.dialCode;

  void setUseEmailLogin(bool email) {
    if (useEmailLogin == email) return;
    useEmailLogin = email;
    update();
  }

  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    update();
  }

  void setCountryCode(String code) {
    if (selectedCountryCode != code) {
      selectedCountryCode = code;
      update();
    }
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'email_required'.tr;
    }
    final trimmed = value.trim();
    if (!GetUtils.isEmail(trimmed)) {
      return 'email_invalid'.tr;
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'password_required'.tr;
    }
    if (value.length < 6) {
      return 'password_min_length'.tr;
    }
    return null;
  }

  Future<void> login() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading = true;
    update();

    final password = passwordController.text.trim();
    final LoginParams params = useEmailLogin
        ? LoginParams(email: emailController.text.trim(), password: password)
        : LoginParams(
            phone: '$selectedCountryCode${phoneController.text.trim()}',
            password: password,
          );

    final result = await loginUseCase(params);

    result.fold(
      (failure) {
        isLoading = false;
        update();
        AppMessages.showSnackBar(
          type: ErrorType.error,
          title: 'error'.tr,
          message: failure.message ?? 'login_failed'.tr,
        );
      },
      (loginResponse) {
        isLoading = false;
        update();

        globalController.setUser(loginResponse.user);
        globalController.token = loginResponse.accessToken;

        AppMessages.showSnackBar(
          type: ErrorType.success,
          title: 'success'.tr,
          message: 'login_success'.tr,
        );

        Get.offAllNamed(AppRoutes.main);
      },
    );
  }

  @override
  void onClose() {
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}

import 'package:alma_desktop/core/config/app_routes.dart';
import 'package:alma_desktop/core/errors/app_messages.dart';
import 'package:alma_desktop/core/widgets/action_message_bottom_sheet.dart';
import 'package:alma_desktop/features/auth/domain/usecases/reset_password_use_case.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ResetPasswordController extends GetxController {
  final ResetPasswordUseCase resetPasswordUseCase;

  ResetPasswordController({required this.resetPasswordUseCase});

  // Form Key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Text Controllers
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmationController =
      TextEditingController();

  // State
  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxBool isPasswordConfirmationVisible = false.obs;
  String? resetToken;

  @override
  void onInit() {
    super.onInit();
    // Get reset token from arguments
    final arguments = Get.arguments;
    if (arguments is Map<String, dynamic> &&
        arguments.containsKey('reset_token')) {
      resetToken = arguments['reset_token'] as String;
    }
  }

  // Validators
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'password_required'.tr;
    }
    if (value.length < 8) {
      return 'password_min_length_8'.tr;
    }
    return null;
  }

  String? validatePasswordConfirmation(String? value) {
    if (value == null || value.isEmpty) {
      return 'password_confirmation_required'.tr;
    }
    if (value != passwordController.text) {
      return 'password_confirmation_not_match'.tr;
    }
    return null;
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  // Toggle password confirmation visibility
  void togglePasswordConfirmationVisibility() {
    isPasswordConfirmationVisible.value = !isPasswordConfirmationVisible.value;
  }

  // Reset password function
  Future<void> resetPassword() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (resetToken == null || resetToken!.isEmpty) {
      AppMessages.showSnackBar(
        type: ErrorType.error,
        title: 'error'.tr,
        message: 'reset_token_required'.tr,
      );
      return;
    }

    isLoading.value = true;

    final result = await resetPasswordUseCase(
      ResetPasswordParams(
        resetToken: resetToken!,
        password: passwordController.text.trim(),
        passwordConfirmation: passwordConfirmationController.text.trim(),
      ),
    );

    result.fold(
      (failure) {
        isLoading.value = false;
        ActionMessageBottomSheet.show(
          context: Get.context!,
          type: MessageType.error,
          title: 'error'.tr,
          message: failure.message ?? 'reset_password_failed'.tr,
        );
      },
      (message) {
        isLoading.value = false;

        // Show success message using ActionMessageBottomSheet
        ActionMessageBottomSheet.show(
          context: Get.context!,
          type: MessageType.success,
          title: 'success'.tr,
          message: message,
          autoCloseDuration: const Duration(seconds: 3),
          onAction: () {
            // Navigate to login screen after success
            Get.offAllNamed(AppRoutes.login);
          },
        );
      },
    );
  }

  @override
  void onClose() {
    passwordController.dispose();
    passwordConfirmationController.dispose();
    super.onClose();
  }
}

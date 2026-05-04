import 'package:alma_desktop/core/config/app_routes.dart';
import 'package:alma_desktop/core/errors/app_messages.dart';
import 'package:alma_desktop/core/widgets/action_message_bottom_sheet.dart';
import 'package:alma_desktop/features/auth/domain/usecases/forget_password_use_case.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgetPasswordController extends GetxController {
  final ForgetPasswordUseCase forgetPasswordUseCase;

  ForgetPasswordController({required this.forgetPasswordUseCase});

  // Form Key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Text Controllers
  final TextEditingController phoneController = TextEditingController();

  // State
  final RxBool isLoading = false.obs;
  String? selectedCountryCode = '+965'; // Default to Kuwait

  // Validators
  String? validatePhone(String value) {
    if (value.isEmpty) {
      return 'phone_required'.tr;
    }

    // Remove any spaces, dashes, or other non-digit characters
    final cleanedValue = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Validate based on country code
    // Kuwait: 8 digits starting with 5-9
    if (selectedCountryCode == '+965') {
      final regex = RegExp(r'^[5-9]\d{7}$');
      if (!regex.hasMatch(cleanedValue)) {
        return 'phone_invalid'.tr;
      }
    } else {
      // Basic validation for other countries
      if (cleanedValue.length < 8) {
        return 'phone_invalid'.tr;
      }
    }

    return null; // Return null for valid input
  }

  // Set country code
  void setCountryCode(String code) {
    if (selectedCountryCode != code) {
      selectedCountryCode = code;
      update();
    }
  }

  // Forget password function
  Future<void> forgetPassword() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

    // Combine country code with phone number
    final fullPhoneNumber =
        '$selectedCountryCode${phoneController.text.trim()}';

    final result = await forgetPasswordUseCase(
      ForgetPasswordParams(phone: fullPhoneNumber),
    );

    result.fold(
      (failure) {
        isLoading.value = false;
        AppMessages.showSnackBar(
          type: ErrorType.error,
          title: 'error'.tr,
          message: failure.message ?? 'forget_password_failed'.tr,
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
            // Navigate to OTP screen after success with phone number
            Get.toNamed(AppRoutes.otp, arguments: {'phone': fullPhoneNumber});
          },
        );
      },
    );
  }

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }
}

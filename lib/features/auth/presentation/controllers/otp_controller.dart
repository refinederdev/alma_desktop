import 'package:alma_desktop/core/config/app_routes.dart';
import 'package:alma_desktop/core/errors/app_messages.dart';
import 'package:alma_desktop/core/widgets/action_message_bottom_sheet.dart';
import 'package:alma_desktop/features/auth/domain/usecases/validate_otp_use_case.dart';
import 'package:get/get.dart';

class OtpController extends GetxController {
  final ValidateOtpUseCase validateOtpUseCase;

  OtpController({required this.validateOtpUseCase});

  // State
  final RxBool isLoading = false.obs;
  final RxString otpCode = ''.obs;
  String? phoneNumber;

  @override
  void onInit() {
    super.onInit();
    // Get phone number from arguments
    final arguments = Get.arguments;
    if (arguments is Map<String, dynamic> && arguments.containsKey('phone')) {
      phoneNumber = arguments['phone'] as String;
    }
  }

  // Set OTP code
  void setOtpCode(String code) {
    otpCode.value = code;
  }

  // Validate OTP function
  Future<void> validateOtp() async {
    if (otpCode.value.length != 6) {
      AppMessages.showSnackBar(
        type: ErrorType.error,
        title: 'error'.tr,
        message: 'otp_invalid'.tr,
      );
      return;
    }

    if (phoneNumber == null || phoneNumber!.isEmpty) {
      AppMessages.showSnackBar(
        type: ErrorType.error,
        title: 'error'.tr,
        message: 'phone_required'.tr,
      );
      return;
    }

    isLoading.value = true;

    final result = await validateOtpUseCase(
      ValidateOtpParams(phone: phoneNumber!, otp: otpCode.value),
    );

    result.fold(
      (failure) {
        isLoading.value = false;
        ActionMessageBottomSheet.show(
          context: Get.context!,
          type: MessageType.error,
          title: 'error'.tr,
          message: failure.message ?? 'otp_validation_failed'.tr,
          autoCloseDuration: const Duration(seconds: 3),
        );
      },
      (validateOtpResponse) {
        isLoading.value = false;

        // Show success message using ActionMessageBottomSheet
        ActionMessageBottomSheet.show(
          context: Get.context!,
          type: MessageType.success,
          title: 'success'.tr,
          message: 'otp_validated_successfully'.tr,
          autoCloseDuration: const Duration(seconds: 3),
          onAction: () {
            // Navigate to reset password screen with reset token
            Get.toNamed(
              AppRoutes.resetPassword,
              arguments: {'reset_token': validateOtpResponse.resetToken},
            );
          },
        );
      },
    );
  }
}

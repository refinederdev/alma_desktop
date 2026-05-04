import 'package:alma_desktop/core/errors/app_messages.dart';
import 'package:alma_desktop/features/auth/domain/usecases/update_profile_use_case.dart';
import 'package:alma_desktop/features/global/presentation/controllers/global_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  ProfileController({required this.updateProfileUseCase});

  final UpdateProfileUseCase updateProfileUseCase;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool isSaving = false;

  @override
  void onInit() {
    super.onInit();
    _fillFromCurrentUser();
  }

  void _fillFromCurrentUser() {
    final user = GlobalController.to.user;
    if (user == null) return;
    firstNameController.text = user.firstName;
    lastNameController.text = user.lastName;
    emailController.text = user.email;
    phoneController.text = user.phone;
  }

  void resetFormValues() {
    _fillFromCurrentUser();
    update();
  }

  String? validateRequired(String? value, String key) {
    if (value == null || value.trim().isEmpty) return key.tr;
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'email_required'.tr;
    if (!GetUtils.isEmail(value.trim())) return 'email_invalid'.tr;
    return null;
  }

  Future<void> saveProfile() async {
    final state = formKey.currentState;
    if (state == null || !state.validate()) return;

    isSaving = true;
    update();

    final result = await updateProfileUseCase(
      UpdateProfileParams(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        language: GlobalController.to.currentLocale.languageCode,
      ),
    );

    result.fold(
      (failure) {
        isSaving = false;
        update();
        AppMessages.showSnackBar(
          type: ErrorType.error,
          title: 'error'.tr,
          message: failure.message ?? 'profile_update_failed'.tr,
        );
      },
      (updatedUser) {
        GlobalController.to.setUser(updatedUser);
        isSaving = false;
        update();
        AppMessages.showSnackBar(
          type: ErrorType.success,
          title: 'success'.tr,
          message: 'profile_updated_successfully'.tr,
        );
      },
    );
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}

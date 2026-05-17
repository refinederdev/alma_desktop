import 'package:alma_desktop/core/config/app_config.dart';
import 'package:alma_desktop/core/errors/app_messages.dart';
import 'package:alma_desktop/core/services/server_config_service/server_config_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ServerConfigController extends GetxController {
  ServerConfigController({required ServerConfigService serverConfigService})
      : _serverConfigService = serverConfigService;

  final ServerConfigService _serverConfigService;

  final formKey = GlobalKey<FormState>();
  final urlController = TextEditingController();
  final isSaving = false.obs;

  String get defaultBaseUrl => AppConfig.defaultBaseURL;

  @override
  void onInit() {
    super.onInit();
    urlController.text = AppConfig.baseURL;
  }

  @override
  void onClose() {
    urlController.dispose();
    super.onClose();
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    isSaving.value = true;
    try {
      final normalized =
          ServerConfigService.normalizeApiBaseUrl(urlController.text);
      await AppConfig.applyBaseUrl(normalized, _serverConfigService);
      urlController.text = AppConfig.baseURL;
      AppMessages.showSnackBar(
        type: ErrorType.success,
        title: 'server_config_saved_title',
        message: 'server_config_saved_message'.tr,
        duration: 4,
      );
    } on FormatException catch (e) {
      AppMessages.showSnackBar(
        type: ErrorType.error,
        title: 'error',
        message: _formatErrorMessage(e.message),
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> resetToDefault() async {
    isSaving.value = true;
    try {
      await AppConfig.resetBaseUrl(_serverConfigService);
      urlController.text = AppConfig.baseURL;
      AppMessages.showSnackBar(
        type: ErrorType.info,
        title: 'server_config_reset_title',
        message: 'server_config_reset_message'.tr,
        duration: 3,
      );
    } finally {
      isSaving.value = false;
    }
  }

  String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'server_config_url_required'.tr;
    }
    try {
      ServerConfigService.normalizeApiBaseUrl(value);
      return null;
    } on FormatException catch (e) {
      return _formatErrorMessage(e.message);
    }
  }

  String _formatErrorMessage(String? code) {
    switch (code) {
      case 'empty_url':
        return 'server_config_url_required'.tr;
      case 'invalid_url':
        return 'server_config_url_invalid'.tr;
      default:
        return 'server_config_url_invalid'.tr;
    }
  }
}

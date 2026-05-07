import 'package:alma_desktop/core/errors/app_messages.dart';
import 'package:alma_desktop/core/services/app_update_service.dart';
import 'package:get/get.dart';
import 'dart:io';

class UpdateController extends GetxController {
  UpdateController({required this.updateService});

  final AppUpdateService updateService;

  bool isChecking = false;
  bool isDownloading = false;
  bool isInstalling = false;
  double downloadProgress = 0;
  String? errorMessage;
  UpdateInfo? updateInfo;
  String currentVersion = '--';

  @override
  void onInit() {
    super.onInit();
    checkForUpdates();
  }

  Future<void> checkForUpdates() async {
    isChecking = true;
    errorMessage = null;
    update();
    try {
      currentVersion = await updateService.getCurrentVersion();
      update();
    } catch (_) {
      // Keep fallback value when version lookup fails.
    }

    try {
      updateInfo = await updateService.checkForUpdate();
      currentVersion = updateInfo?.currentVersion ?? currentVersion;
      if (updateInfo?.checkError != null) {
        errorMessage = 'update_check_failed'.tr;
      }
    } catch (_) {
      errorMessage = 'update_check_failed'.tr;
    } finally {
      isChecking = false;
      update();
    }
  }

  Future<void> updateNow() async {
    final info = updateInfo;
    if (info == null) return;
    final url = info.downloadUrl;
    if (url == null || url.isEmpty) {
      AppMessages.showSnackBar(
        type: ErrorType.error,
        title: 'error'.tr,
        message: 'update_download_unavailable'.tr,
      );
      return;
    }

    isDownloading = true;
    downloadProgress = 0;
    errorMessage = null;
    update();

    try {
      final installerPath = await updateService.downloadInstaller(
        url: url,
        onProgress: (received, total) {
          if (total > 0) {
            downloadProgress = received / total;
            update();
          }
        },
      );

      isDownloading = false;
      isInstalling = true;
      update();

      await updateService.installAndExit(installerPath);

      isDownloading = false;
      isInstalling = false;
      update();

      if (Platform.isMacOS) {
        AppMessages.showSnackBar(
          type: ErrorType.success,
          title: 'success'.tr,
          message: 'update_downloaded_open_in_finder'.tr,
        );
      }
    } catch (_) {
      isDownloading = false;
      isInstalling = false;
      errorMessage = 'update_install_failed'.tr;
      update();
      AppMessages.showSnackBar(
        type: ErrorType.error,
        title: 'error'.tr,
        message: errorMessage,
      );
    }
  }
}

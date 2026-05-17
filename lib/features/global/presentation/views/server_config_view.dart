import 'package:alma_desktop/core/theme/alma_tokens.dart';
import 'package:alma_desktop/core/theme/app_styles.dart';
import 'package:alma_desktop/core/theme/app_theme.dart';
import 'package:alma_desktop/core/widgets/app_button.dart';
import 'package:alma_desktop/core/widgets/app_input.dart';
import 'package:alma_desktop/features/global/presentation/controllers/server_config_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ServerConfigView extends GetView<ServerConfigController> {
  const ServerConfigView({super.key});

  @override
  Widget build(BuildContext context) {
    final alma = context.alma;

    return Scaffold(
      backgroundColor: alma.scaffoldBg,
      appBar: AppBar(
        backgroundColor: alma.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: alma.onSurface),
          onPressed: Get.back,
        ),
        title: Text(
          'server_config_title'.tr,
          style: AppStyles.titleMedium.copyWith(
            color: alma.onSurfaceTitle,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 560.w),
            child: Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: alma.surface,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: alma.outline),
              ),
              child: Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'server_config_subtitle'.tr,
                      style: AppStyles.bodyMedium.copyWith(
                        color: alma.onSurfaceSecondary,
                        height: 1.45,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    AppInputField(
                      label: 'server_config_url_label'.tr,
                      hint: 'server_config_url_hint'.tr,
                      controller: controller.urlController,
                      keyboardType: TextInputType.url,
                      validator: controller.validateUrl,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      '${'server_config_default_label'.tr}: ${controller.defaultBaseUrl}',
                      style: AppStyles.bodySmall.copyWith(
                        color: alma.onSurfaceTertiary,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Obx(
                      () => AppButton(
                        text: 'save'.tr,
                        isLoading: controller.isSaving.value,
                        onPressed: controller.isSaving.value
                            ? null
                            : controller.save,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Obx(
                      () => AppButton(
                        text: 'server_config_reset_button'.tr,
                        isDisabled: controller.isSaving.value,
                        onPressed: controller.isSaving.value
                            ? null
                            : controller.resetToDefault,
                        backgroundColor: alma.surface,
                        textColor: AppTheme.brandMain2_600,
                        borderColor: alma.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

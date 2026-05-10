import 'package:alma_desktop/core/theme/alma_tokens.dart';
import 'package:alma_desktop/core/theme/app_styles.dart';
import 'package:alma_desktop/core/theme/app_theme.dart';
import 'package:alma_desktop/core/widgets/app_button.dart';
import 'package:alma_desktop/core/widgets/app_input.dart';
import 'package:alma_desktop/features/global/presentation/controllers/global_controller.dart';
import 'package:alma_desktop/features/main/presentation/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (c) {
        final user = GlobalController.to.user;
        return SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 760.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'profile'.tr,
                  style: AppStyles.titleLarge.copyWith(
                    color: context.alma.onSurfaceTitle,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  user?.fullName ?? '',
                  style: AppStyles.bodyMedium
                      .copyWith(color: context.alma.onSurfaceTertiary),
                ),
                SizedBox(height: 16.h),
                _ProfileCard(controller: c),
                SizedBox(height: 14.h),
                const _AppearanceCard(),
                SizedBox(height: 14.h),
                _LanguageCard(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    final alma = context.alma;
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: alma.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: alma.outline),
      ),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'edit_profile'.tr,
              style: AppStyles.titleMedium.copyWith(
                color: alma.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: AppInputField(
                    label: 'first_name'.tr,
                    hint: 'enter_first_name'.tr,
                    controller: controller.firstNameController,
                    validator: (v) =>
                        controller.validateRequired(v, 'first_name_required'),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: AppInputField(
                    label: 'last_name'.tr,
                    hint: 'enter_last_name'.tr,
                    controller: controller.lastNameController,
                    validator: (v) =>
                        controller.validateRequired(v, 'last_name_required'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            AppInputField(
              label: 'email'.tr,
              hint: 'enter_email'.tr,
              keyboardType: TextInputType.emailAddress,
              controller: controller.emailController,
              validator: controller.validateEmail,
            ),
            SizedBox(height: 10.h),
            AppInputField(
              label: 'phone'.tr,
              hint: 'phone'.tr,
              keyboardType: TextInputType.phone,
              controller: controller.phoneController,
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'update_profile'.tr,
                    isLoading: controller.isSaving,
                    onPressed: controller.saveProfile,
                  ),
                ),
                SizedBox(width: 10.w),
                OutlinedButton(
                  onPressed: controller.resetFormValues,
                  child: Text('cancel'.tr),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context) {
    final alma = context.alma;
    return GetBuilder<GlobalController>(
      builder: (global) {
        return Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: alma.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: alma.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'appearance'.tr,
                style: AppStyles.titleMedium.copyWith(
                  color: alma.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'choose_theme_description'.tr,
                style: AppStyles.bodySmall
                    .copyWith(color: alma.onSurfaceTertiary),
              ),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: [
                  _ThemeModeChoice(
                    label: 'theme_system'.tr,
                    selected: global.themeMode == ThemeMode.system,
                    onTap: () => global.setThemeMode(ThemeMode.system),
                  ),
                  _ThemeModeChoice(
                    label: 'theme_light'.tr,
                    selected: global.themeMode == ThemeMode.light,
                    onTap: () => global.setThemeMode(ThemeMode.light),
                  ),
                  _ThemeModeChoice(
                    label: 'theme_dark'.tr,
                    selected: global.themeMode == ThemeMode.dark,
                    onTap: () => global.setThemeMode(ThemeMode.dark),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeModeChoice extends StatelessWidget {
  const _ThemeModeChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final alma = context.alma;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999.r),
          color: selected ? alma.selectionSoftBg : alma.surface,
          border: Border.all(
            color: selected ? AppTheme.brandMain2_600 : alma.outline,
          ),
        ),
        child: Text(
          label,
          style: AppStyles.labelLarge.copyWith(
            color: selected ? AppTheme.brandMain2_600 : alma.onSurfaceSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final alma = context.alma;
    return GetBuilder<GlobalController>(
      builder: (global) {
        final isArabic = global.currentLocale.languageCode == 'ar';
        return Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: alma.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: alma.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'change_language'.tr,
                style: AppStyles.titleMedium.copyWith(
                  color: alma.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'choose_interface_language'.tr,
                style: AppStyles.bodySmall
                    .copyWith(color: alma.onSurfaceTertiary),
              ),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: [
                  _LanguageChoice(
                    label: 'العربية',
                    selected: isArabic,
                    onTap: () => global.changeLocale(const Locale('ar', 'SA')),
                  ),
                  _LanguageChoice(
                    label: 'English',
                    selected: !isArabic,
                    onTap: () => global.changeLocale(const Locale('en', 'US')),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LanguageChoice extends StatelessWidget {
  const _LanguageChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final alma = context.alma;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999.r),
          color: selected ? alma.selectionSoftBg : alma.surface,
          border: Border.all(
            color: selected ? AppTheme.brandMain2_600 : alma.outline,
          ),
        ),
        child: Text(
          label,
          style: AppStyles.labelLarge.copyWith(
            color:
                selected ? AppTheme.brandMain2_600 : alma.onSurfaceSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

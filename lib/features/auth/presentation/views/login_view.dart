import 'package:alma_desktop/core/theme/alma_tokens.dart';
import 'package:alma_desktop/core/theme/app_styles.dart';
import 'package:alma_desktop/core/theme/app_theme.dart';
import 'package:alma_desktop/core/widgets/app_button.dart';
import 'package:alma_desktop/core/widgets/app_input.dart';
import 'package:alma_desktop/core/widgets/app_phone_input.dart';
import 'package:alma_desktop/core/widgets/alma_brand_logo.dart';
import 'package:alma_desktop/core/widgets/change_locale_bottom_sheet.dart';
import 'package:alma_desktop/features/auth/presentation/controllers/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: context.alma.scaffoldBg,
      body: Row(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Expanded(flex: 11, child: _BrandingPanel()),
          Expanded(
            flex: 9,
            child: _FormPanel(),
          ),
        ],
      ),
    );
  }
}

class _BrandingPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -60.h,
            right: -40.w,
            child: _GlowCircle(diameter: 220.w, opacity: 0.12),
          ),
          Positioned(
            bottom: 80.h,
            left: -50.w,
            child: _GlowCircle(diameter: 180.w, opacity: 0.1),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 56.w, vertical: 48.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AlmaBrandLogo(
                  assetPath: 'assets/images/alma-full-logo.png',
                  markSize: 100,
                  maxWidth: 340,
                  showWordmark: false,
                  wordmarkColor: AppTheme.baseWhite,
                ),
                SizedBox(height: 36.h),
                Text(
                  'your_customers_are_smarter_with_alma'.tr,
                  style: AppStyles.headlineSmall.copyWith(
                    color: AppTheme.baseWhite,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'organize_your_work_follow_your_customers_and_best_results'.tr,
                  style: AppStyles.bodyLarge.copyWith(
                    color: AppTheme.baseWhite.withValues(alpha: 0.88),
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: AppTheme.baseWhite.withValues(alpha: 0.85),
                      size: 22.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'login_subtitle_desktop'.tr,
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppTheme.baseWhite.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.diameter, required this.opacity});

  final double diameter;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.baseWhite.withValues(alpha: opacity),
      ),
    );
  }
}

class _FormPanel extends GetView<LoginController> {
  @override
  Widget build(BuildContext context) {
    final alma = context.alma;
    return ColoredBox(
      color: alma.scaffoldBg,
      child: Stack(
        children: [
          Positioned(
            top: 20.h,
            right: Directionality.of(context) == TextDirection.rtl ? null : 24.w,
            left: Directionality.of(context) == TextDirection.rtl ? 24.w : null,
            child: IconButton(
              tooltip: 'change_language'.tr,
              onPressed: () => ChangeLocaleBottomSheet.show(context),
              icon: Icon(
                Icons.language_rounded,
                color: alma.onSurfaceSecondary,
                size: 26.sp,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 32.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 440.w),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 36.w, vertical: 40.h),
                  decoration: BoxDecoration(
                    color: alma.surface,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: alma.shadowSM,
                    border: Border.all(color: alma.outlineVariant),
                  ),
                  child: Form(
                    key: controller.formKey,
                    child: GetBuilder<LoginController>(
                      builder: (c) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'login'.tr,
                            textAlign: TextAlign.center,
                            style: AppStyles.headlineSmall.copyWith(
                              color: alma.onSurfaceTitle,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'please_enter_your_details_to_login'.tr,
                            textAlign: TextAlign.center,
                            style: AppStyles.bodyMedium.copyWith(
                              color: alma.onSurfaceSecondary,
                            ),
                          ),
                          SizedBox(height: 28.h),
                          _MethodToggle(),
                          SizedBox(height: 24.h),
                          if (c.useEmailLogin) ...[
                            AppInputField(
                              label: 'email'.tr,
                              hint: 'enter_email'.tr,
                              controller: c.emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              validator: c.validateEmail,
                              prefixIcon: Icon(
                                Icons.alternate_email_rounded,
                                color: alma.onSurfaceHint,
                                size: 22.sp,
                              ),
                            ),
                          ] else ...[
                            AppPhoneInput(
                              label: 'phone'.tr,
                              hint: '5XXXXXXX',
                              controller: c.phoneController,
                              initialCountry: Country.kuwait,
                              onCountryChanged: c.setCountryCode,
                            ),
                          ],
                          SizedBox(height: 20.h),
                          AppInputField(
                            label: 'password'.tr,
                            hint: 'password'.tr,
                            controller: c.passwordController,
                            isPassword: true,
                            obscureText: !c.isPasswordVisible,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            validator: c.validatePassword,
                            onFieldSubmitted: (_) => c.login(),
                            prefixIcon: Icon(
                              Icons.lock_outline_rounded,
                              color: alma.onSurfaceHint,
                              size: 22.sp,
                            ),
                            suffixIcon: IconButton(
                              splashRadius: 22,
                              onPressed: c.togglePasswordVisibility,
                              icon: Icon(
                                c.isPasswordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: alma.onSurfaceTertiary,
                                size: 22.sp,
                              ),
                            ),
                          ),
                          SizedBox(height: 28.h),
                          AppButton(
                            text: 'login'.tr,
                            width: double.infinity,
                            height: 52.h,
                            isLoading: c.isLoading,
                            isDisabled: c.isLoading,
                            onPressed: c.login,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodToggle extends GetView<LoginController> {
  @override
  Widget build(BuildContext context) {
    final alma = context.alma;
    return GetBuilder<LoginController>(
      builder: (c) {
        return Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: alma.outline.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: alma.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ToggleChip(
                  label: 'login_method_email'.tr,
                  selected: c.useEmailLogin,
                  onTap: () => c.setUseEmailLogin(true),
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _ToggleChip(
                  label: 'login_method_phone'.tr,
                  selected: !c.useEmailLogin,
                  onTap: () => c.setUseEmailLogin(false),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: selected ? alma.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: selected ? alma.shadowXS : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppStyles.titleSmall.copyWith(
              color: selected ? alma.onSurfaceTitle : alma.onSurfaceSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

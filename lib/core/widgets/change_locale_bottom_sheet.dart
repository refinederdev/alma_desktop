import 'package:alma_desktop/core/theme/app_styles.dart';
import 'package:alma_desktop/core/theme/app_theme.dart';
import 'package:alma_desktop/core/widgets/app_button.dart';
import 'package:alma_desktop/core/widgets/language_option_widget.dart';
import 'package:alma_desktop/features/global/presentation/controllers/global_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// تبديل اللغة: على الشاشات العريضة يُعرض كحوار سطح مكتب؛ على العرض الضيق يبقى شكل البطاقة السفلية.
abstract final class ChangeLocaleBottomSheet {
  ChangeLocaleBottomSheet._();

  static const double _desktopBreakpoint = 720;

  static Future<void> show(BuildContext context) async {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= _desktopBreakpoint) {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierColor: AppTheme.gray900.withValues(alpha: 0.45),
        builder: (ctx) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: EdgeInsets.symmetric(horizontal: 48.w, vertical: 40.h),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 520.w),
              child: Material(
                color: AppTheme.baseWhite,
                elevation: 28,
                shadowColor: AppTheme.baseBlack.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20.r),
                clipBehavior: Clip.antiAlias,
                child: const _LocalePickerBody(isDesktop: true),
              ),
            ),
          );
        },
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final bottom = MediaQuery.paddingOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h + bottom),
          child: Material(
            color: AppTheme.baseWhite,
            elevation: 16,
            shadowColor: AppTheme.baseBlack.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20.r),
            clipBehavior: Clip.antiAlias,
            child: const _LocalePickerBody(isDesktop: false),
          ),
        );
      },
    );
  }
}

class _LocalePickerBody extends StatelessWidget {
  const _LocalePickerBody({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<GlobalController>(
      init: Get.find<GlobalController>(),
      builder: (controller) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 28.w : 20.w,
            isDesktop ? 24.h : 12.h,
            isDesktop ? 28.w : 20.w,
            isDesktop ? 24.h : 20.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isDesktop) ...[
                Center(
                  child: Container(
                    width: 48.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      color: AppTheme.gray200,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'change_language'.tr,
                      style: AppStyles.titleLarge.copyWith(
                        color: AppTheme.gray900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isDesktop)
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppTheme.gray500,
                        size: 24.sp,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                'choose_interface_language'.tr,
                style: AppStyles.bodySmall.copyWith(
                  color: AppTheme.gray400,
                  height: 1.4,
                ),
              ),
              SizedBox(height: isDesktop ? 24.h : 16.h),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: LanguageOptionWidget(
                        flagUrl: 'https://flagsapi.com/SA/flat/64.png',
                        languageName: 'العربية',
                        isSelected: controller.currentLocale.languageCode == 'ar',
                        desktopStyle: true,
                        onPressed: () {
                          controller.changeLocale(const Locale('ar', 'SA'));
                        },
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: LanguageOptionWidget(
                        flagUrl: 'https://flagsapi.com/US/flat/64.png',
                        languageName: 'English',
                        isSelected: controller.currentLocale.languageCode == 'en',
                        desktopStyle: true,
                        onPressed: () {
                          controller.changeLocale(const Locale('en', 'US'));
                        },
                      ),
                    ),
                  ],
                )
              else ...[
                LanguageOptionWidget(
                  flagUrl: 'https://flagsapi.com/SA/flat/32.png',
                  languageName: 'العربية',
                  isSelected: controller.currentLocale.languageCode == 'ar',
                  onPressed: () {
                    controller.changeLocale(const Locale('ar', 'SA'));
                  },
                ),
                SizedBox(height: 12.h),
                LanguageOptionWidget(
                  flagUrl: 'https://flagsapi.com/US/flat/32.png',
                  languageName: 'English',
                  isSelected: controller.currentLocale.languageCode == 'en',
                  onPressed: () {
                    controller.changeLocale(const Locale('en', 'US'));
                  },
                ),
              ],
              SizedBox(height: isDesktop ? 28.h : 20.h),
              AppButton(
                text: 'done'.tr,
                width: double.infinity,
                height: isDesktop ? 56.h : 52.h,
                padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 24.w),
                onPressed: () => Get.back<void>(),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:alma_desktop/core/theme/app_styles.dart';
import 'package:alma_desktop/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// شعار Alma من PNG (الشعار الكامل). يمكن إضافة كلمة «Alma» تحته عند [showWordmark].
class AlmaBrandLogo extends StatelessWidget {
  const AlmaBrandLogo({
    super.key,
    this.assetPath = 'assets/images/alma-full-logo.png',
    this.markSize = 88,
    this.maxWidth = 320,
    this.showWordmark = false,
    this.wordmarkColor = AppTheme.baseWhite,
    this.spacing = 16,
    this.alignment = CrossAxisAlignment.start,
  });

  /// مسار ملف الشعار PNG.
  final String assetPath;

  /// أقصى ارتفاع للشعار (بعد `.h` من ScreenUtil).
  final double markSize;

  /// أقصى عرض للشعار (بعد `.w`) ليتناسب مع الشعارات الأفقية.
  final double maxWidth;
  final bool showWordmark;
  final Color wordmarkColor;
  final double spacing;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: markSize.h,
            maxWidth: maxWidth.w,
          ),
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.image_not_supported_outlined,
                size: 48.sp,
                color: wordmarkColor.withValues(alpha: 0.6),
              );
            },
          ),
        ),
        if (showWordmark) ...[
          SizedBox(height: spacing.h),
          Text(
            'Alma',
            style: AppStyles.headlineMedium.copyWith(
              color: wordmarkColor,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.25,
              height: 1.1,
            ),
          ),
        ],
      ],
    );
  }
}

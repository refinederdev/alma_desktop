import 'package:alma_desktop/core/theme/app_styles.dart';
import 'package:alma_desktop/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MainPlaceholderView extends StatelessWidget {
  const MainPlaceholderView({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
  });

  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 420.w,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppTheme.gray25,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppTheme.gray50),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 34.sp, color: AppTheme.brandMain2_500),
            SizedBox(height: 12.h),
            Text(
              title,
              style: AppStyles.titleMedium.copyWith(
                color: AppTheme.gray800,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppStyles.bodySmall.copyWith(color: AppTheme.gray400),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:alma_desktop/core/errors/aryaf_toast_card.dart';
import 'package:alma_desktop/core/theme/app_theme.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../theme/app_styles.dart';

class AppMessages {
  static showSnackBar({
    ErrorType type = ErrorType.success,
    String? title = "success",
    String? message = "",
    int duration = 2,
    BuildContext? context,
    bool clearQueue = true,
  }) {
    final activeContext = context ?? Get.context;
    if (activeContext == null) return;
    final palette = _getPalette(type);
    final screenWidth = MediaQuery.sizeOf(activeContext).width;
    final isDesktop = screenWidth >= 900;

    if (clearQueue) {
      DelightToastBar.removeAll();
    }

    return DelightToastBar(
      position: DelightSnackbarPosition.top,
      snackbarDuration: Duration(
        milliseconds: duration.clamp(1, 12) * 1000,
      ),
      animationDuration: const Duration(milliseconds: 360),
      autoDismiss: true,
      builder: (context) {
        return SafeArea(
          child: Align(
            alignment:
                isDesktop ? AlignmentDirectional.topEnd : Alignment.topCenter,
            child: AryafToastCard(
              color: palette.background,
              showCloseButton: isDesktop,
              leading: Icon(
                palette.icon,
                size: isDesktop ? 22.sp : 20.sp,
                color: Colors.white,
              ),
              title: Text(
                (title ?? "success").tr,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppStyles.titleMedium.copyWith(
                  height: 1.2,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                message ?? "",
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppStyles.bodySmall.copyWith(
                  height: 1.25,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        );
      },
    ).show(activeContext);
  }

  static _MessagePalette _getPalette(ErrorType type) {
    switch (type) {
      case ErrorType.success:
        return _MessagePalette(
          background: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.success600, AppTheme.success500],
          ),
          icon: Icons.check_circle_rounded,
        );
      case ErrorType.warning:
        return _MessagePalette(
          background: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.warning700, AppTheme.warning500],
          ),
          icon: Icons.warning_rounded,
        );
      case ErrorType.info:
        return _MessagePalette(
          background: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.brandMain2_600, AppTheme.brandMain2_400],
          ),
          icon: Icons.info_rounded,
        );
      case ErrorType.error:
        return _MessagePalette(
          background: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.error700, AppTheme.error500],
          ),
          icon: Icons.error_rounded,
        );
    }
  }
}

enum ErrorType { success, warning, info, error }

class _MessagePalette {
  final Object background;
  final IconData icon;

  const _MessagePalette({required this.background, required this.icon});
}

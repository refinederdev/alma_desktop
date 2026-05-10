import 'dart:async';

import 'package:alma_desktop/core/theme/alma_tokens.dart';
import 'package:alma_desktop/core/theme/app_theme.dart';
import 'package:alma_desktop/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum MessageType { success, error, warning, info }

class ActionMessageBottomSheet extends StatefulWidget {
  final MessageType type;
  final String title;
  final String message;
  final VoidCallback? onActionPressed;
  final String? actionText;
  final Duration? autoCloseDuration;
  final VoidCallback? onAction;

  const ActionMessageBottomSheet({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.onActionPressed,
    this.actionText,
    this.autoCloseDuration,
    this.onAction,
  });

  /// دالة static لعرض الـ bottom sheet
  static void show({
    required BuildContext context,
    required MessageType type,
    required String title,
    required String message,
    VoidCallback? onActionPressed,
    String? actionText,
    Duration? autoCloseDuration,
    VoidCallback? onAction,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ActionMessageBottomSheet(
        type: type,
        title: title,
        message: message,
        onActionPressed: onActionPressed,
        actionText: actionText,
        autoCloseDuration: autoCloseDuration,
        onAction: onAction,
      ),
    );
  }

  @override
  State<ActionMessageBottomSheet> createState() =>
      _ActionMessageBottomSheetState();
}

class _ActionMessageBottomSheetState extends State<ActionMessageBottomSheet> {
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    if (widget.onActionPressed == null) {
      // إعداد الإغلاق التلقائي (افتراضي 3 ثواني)
      final duration = widget.autoCloseDuration ?? const Duration(seconds: 3);
      _autoCloseTimer = Timer(duration, () {
        if (mounted && Navigator.canPop(context)) {
          // استدعاء onAction إذا كان موجوداً (عند عدم وجود أزرار)
          Navigator.of(context).pop();
          if (widget.onActionPressed == null && widget.onAction != null) {
            widget.onAction?.call();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  /// الحصول على مسار صورة GIF حسب النوع
  String _getGifPath() {
    switch (widget.type) {
      case MessageType.success:
        return 'assets/gifs/success.gif';
      case MessageType.error:
        return 'assets/gifs/error.gif';
      case MessageType.warning:
        return 'assets/gifs/warning.gif';
      case MessageType.info:
        return 'assets/gifs/info.gif';
    }
  }

  /// الحصول على لون الخلفية حسب النوع
  Color _getBackgroundColor() {
    switch (widget.type) {
      case MessageType.success:
        return AppTheme.success25;
      case MessageType.error:
        return AppTheme.error25;
      case MessageType.warning:
        return AppTheme.warning25;
      case MessageType.info:
        return AppTheme.brandMain25;
    }
  }

  /// الحصول على لون النص الرئيسي حسب النوع
  Color _getTextColor() {
    switch (widget.type) {
      case MessageType.success:
        return AppTheme.success700;
      case MessageType.error:
        return AppTheme.error700;
      case MessageType.warning:
        return AppTheme.warning700;
      case MessageType.info:
        return AppTheme.brandMain700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final alma = context.alma;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      decoration: BoxDecoration(
        color: alma.bottomSheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar للسحب
          Container(
            margin: EdgeInsets.only(bottom: 24.h),
            width: 54.w,
            height: 5.h,
            decoration: BoxDecoration(
              color: alma.onSurfaceHint,
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          // صورة GIF
          Container(
            width: 120.w,
            height: 120.h,
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                _getGifPath(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // في حالة عدم وجود الصورة، نعرض أيقونة بديلة
                  return Icon(_getIcon(), size: 60.sp, color: _getTextColor());
                },
              ),
            ),
          ),
          SizedBox(height: 24.h),
          // العنوان
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: alma.onSurfaceTitle,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          // الرسالة
          Text(
            widget.message,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              color: alma.onSurfaceSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          // الأزرار (فقط إذا تم تمرير زر إجراء)
          if (widget.onActionPressed != null && widget.actionText != null) ...[
            SizedBox(height: 32.h),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    backgroundColor: _getTextColor(),
                    textColor: Colors.white,
                    borderColor: _getTextColor(),
                    text: widget.actionText!,
                    onPressed: () {
                      _autoCloseTimer?.cancel();
                      widget.onActionPressed?.call();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: AppButton(
                    // إلغاء
                    backgroundColor: AppTheme.brandMain2.withValues(
                      alpha: 0.08,
                    ),
                    textColor: AppTheme.brandMain2,
                    borderColor: AppTheme.brandMain2.withValues(alpha: 0.08),
                    text: 'إلغاء',
                    onPressed: () {
                      _autoCloseTimer?.cancel();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// الحصول على أيقونة بديلة في حالة عدم وجود الصورة
  IconData _getIcon() {
    switch (widget.type) {
      case MessageType.success:
        return Icons.check_circle;
      case MessageType.error:
        return Icons.error;
      case MessageType.warning:
        return Icons.warning;
      case MessageType.info:
        return Icons.info;
    }
  }
}

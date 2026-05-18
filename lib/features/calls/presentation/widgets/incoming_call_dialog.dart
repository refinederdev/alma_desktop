import 'package:alma_desktop/core/theme/alma_tokens.dart';
import 'package:alma_desktop/core/theme/app_styles.dart';
import 'package:alma_desktop/core/theme/app_theme.dart';
import 'package:alma_desktop/features/calls/presentation/controllers/call_controller.dart';
import 'package:alma_desktop/features/calls/presentation/widgets/call_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// حوار يظهر فوق التطبيق عند ورود مكالمة، يعرض اسم المتصل ورقمه مع أزرار قبول/رفض.
class IncomingCallDialog extends StatelessWidget {
  const IncomingCallDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CallController>(
      builder: (c) {
        // إذا انتقلنا إلى inProgress من نفس الحوار، نستبدله بحوار المكالمة النشطة
        if (c.phase == CallUiPhase.inProgress) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            c.switchToActiveDialog();
          });
        }
        // إذا انتهت المكالمة لأي سبب نُغلق
        if (c.phase == CallUiPhase.ended || c.phase == CallUiPhase.idle) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Get.isDialogOpen ?? false) {
              Get.back();
            }
          });
        }
        final call = c.currentCall;
        final session = c.currentSession;
        final name = (call?.contactName?.trim().isNotEmpty == true)
            ? call!.contactName!
            : (call?.displayPhone ?? '—');
        final phone = call?.displayPhone ?? '';

        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          backgroundColor: context.alma.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
            side: BorderSide(color: context.alma.outline),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 420.w),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.brandMain2_100,
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.phone_in_talk_rounded,
                          color: AppTheme.brandMain2_600,
                          size: 16.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'incoming_call'.tr,
                          style: AppStyles.labelMedium.copyWith(
                            color: AppTheme.brandMain2_600,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 18.h),
                  CallAvatar(label: name, pulse: true, size: 96),
                  SizedBox(height: 14.h),
                  Text(
                    name,
                    style: AppStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.alma.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (phone.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      phone,
                      style: AppStyles.bodyMedium.copyWith(
                        color: context.alma.onSurfaceSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (session?.sessionName != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      '${'on_session'.tr} ${session!.sessionName}',
                      style: AppStyles.labelSmall.copyWith(
                        color: context.alma.onSurfaceTertiary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  SizedBox(height: 8.h),
                  Text(
                    'calling_via_whatsapp'.tr,
                    style: AppStyles.bodySmall.copyWith(
                      color: context.alma.onSurfaceHint,
                    ),
                  ),
                  SizedBox(height: 22.h),
                  Row(
                    children: [
                      Expanded(
                        child: _CallActionButton(
                          icon: Icons.call_end_rounded,
                          label: 'reject'.tr,
                          color: AppTheme.error500,
                          loading: c.isProcessing &&
                              c.phase == CallUiPhase.ringingIncoming,
                          onPressed: c.isProcessing
                              ? null
                              : () => c.rejectIncomingCall(),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _CallActionButton(
                          icon: Icons.call_rounded,
                          label: 'answer'.tr,
                          color: AppTheme.success500,
                          loading: c.isProcessing &&
                              c.phase != CallUiPhase.ringingIncoming,
                          onPressed: c.isProcessing
                              ? null
                              : () => c.acceptIncomingCall(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CallActionButton extends StatelessWidget {
  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.loading = false,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onPressed,
        child: Container(
          height: 52.h,
          alignment: Alignment.center,
          child: loading
              ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      label,
                      style: AppStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

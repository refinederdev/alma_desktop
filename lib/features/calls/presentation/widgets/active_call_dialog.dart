import 'package:alma_desktop/core/theme/alma_tokens.dart';
import 'package:alma_desktop/core/theme/app_styles.dart';
import 'package:alma_desktop/core/theme/app_theme.dart';
import 'package:alma_desktop/features/calls/presentation/controllers/call_controller.dart';
import 'package:alma_desktop/features/calls/presentation/widgets/call_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// حوار يعرض حالة المكالمة الجارية: ringing/connecting/in-progress + أزرار التحكم.
class ActiveCallDialog extends StatelessWidget {
  const ActiveCallDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CallController>(
      builder: (c) {
        if (c.phase == CallUiPhase.idle) {
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
            constraints: BoxConstraints(maxWidth: 440.w),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PhaseBadge(phase: c.phase),
                  SizedBox(height: 18.h),
                  CallAvatar(
                    label: name,
                    pulse: c.phase == CallUiPhase.outgoingDialing ||
                        c.phase == CallUiPhase.outgoingConnecting ||
                        c.phase == CallUiPhase.outgoingRinging,
                    size: 96,
                  ),
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
                  SizedBox(height: 12.h),
                  if (c.phase == CallUiPhase.inProgress)
                    Text(
                      c.formattedDuration,
                      style: AppStyles.headlineSmall.copyWith(
                        color: AppTheme.brandMain2_600,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    )
                  else
                    Text(
                      _phaseLabel(c.phase),
                      style: AppStyles.bodyMedium.copyWith(
                        color: context.alma.onSurfaceHint,
                      ),
                    ),
                  SizedBox(height: 22.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (c.phase == CallUiPhase.inProgress) ...[
                        _CircleButton(
                          icon: c.isMicMuted
                              ? Icons.mic_off_rounded
                              : Icons.mic_rounded,
                          background: c.isMicMuted
                              ? AppTheme.error500
                              : context.alma.surfaceVariant,
                          foreground: c.isMicMuted
                              ? Colors.white
                              : context.alma.onSurface,
                          onTap: c.toggleMute,
                        ),
                        SizedBox(width: 18.w),
                      ],
                      _CircleButton(
                        icon: Icons.call_end_rounded,
                        background: AppTheme.error500,
                        foreground: Colors.white,
                        onTap: c.isProcessing ? null : c.hangUp,
                        loading: c.isProcessing &&
                            c.phase != CallUiPhase.inProgress,
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

  String _phaseLabel(CallUiPhase phase) {
    switch (phase) {
      case CallUiPhase.outgoingDialing:
        return 'dialing'.tr;
      case CallUiPhase.outgoingConnecting:
        return 'connecting'.tr;
      case CallUiPhase.outgoingRinging:
        return 'ringing'.tr;
      case CallUiPhase.ended:
        return 'call_ended'.tr;
      case CallUiPhase.ringingIncoming:
        return 'incoming_call'.tr;
      case CallUiPhase.inProgress:
        return 'in_progress'.tr;
      case CallUiPhase.idle:
        return '';
    }
  }
}

class _PhaseBadge extends StatelessWidget {
  const _PhaseBadge({required this.phase});

  final CallUiPhase phase;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    late final IconData icon;
    late final String label;
    switch (phase) {
      case CallUiPhase.inProgress:
        bg = AppTheme.success50;
        fg = AppTheme.success700;
        icon = Icons.phone_in_talk_rounded;
        label = 'in_progress'.tr;
        break;
      case CallUiPhase.outgoingDialing:
      case CallUiPhase.outgoingConnecting:
      case CallUiPhase.outgoingRinging:
        bg = AppTheme.brandMain2_100;
        fg = AppTheme.brandMain2_600;
        icon = Icons.phone_forwarded_rounded;
        label = 'outbound_call'.tr;
        break;
      case CallUiPhase.ringingIncoming:
        bg = AppTheme.brandMain2_100;
        fg = AppTheme.brandMain2_600;
        icon = Icons.phone_in_talk_rounded;
        label = 'incoming_call'.tr;
        break;
      case CallUiPhase.ended:
        bg = AppTheme.error50;
        fg = AppTheme.error700;
        icon = Icons.call_end_rounded;
        label = 'call_ended'.tr;
        break;
      case CallUiPhase.idle:
        bg = AppTheme.gray50;
        fg = AppTheme.gray500;
        icon = Icons.phone_rounded;
        label = '';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 16.sp),
          SizedBox(width: 6.w),
          Text(
            label,
            style: AppStyles.labelMedium.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.background,
    required this.foreground,
    this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 60.w,
          height: 60.w,
          child: Center(
            child: loading
                ? SizedBox(
                    width: 22.w,
                    height: 22.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: foreground,
                    ),
                  )
                : Icon(icon, color: foreground, size: 26.sp),
          ),
        ),
      ),
    );
  }
}

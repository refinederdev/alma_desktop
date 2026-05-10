import 'package:alma_desktop/core/theme/app_styles.dart';
import 'package:alma_desktop/core/theme/app_theme.dart';
import 'package:alma_desktop/features/main/presentation/controllers/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// For users with the `agent` role: shows clock-in status on Chat/CRM when not
/// clocked in, so they know new chats may not reach them until they clock in.
class AgentCheckInStatusBanner extends StatelessWidget {
  const AgentCheckInStatusBanner({super.key});

  static bool _shouldShow(DashboardController dash) {
    if (!dash.isAgent) return false;
    if (dash.isClockedIn) return false;
    if (dash.isAttendanceLoading && dash.attendanceStatus == null) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DashboardController>(
      builder: (dash) {
        if (!_shouldShow(dash)) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppTheme.warning50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppTheme.warning200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.schedule_rounded,
                  color: AppTheme.warning800,
                  size: 22.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'not_clocked_in'.tr,
                        style: AppStyles.titleSmall.copyWith(
                          color: AppTheme.warning900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'agent_check_in_workspace_notice'.tr,
                        style: AppStyles.bodySmall.copyWith(
                          color: AppTheme.warning800,
                          height: 1.35,
                        ),
                      ),
                      if (dash.attendanceErrorMessage != null) ...[
                        SizedBox(height: 6.h),
                        Text(
                          dash.attendanceErrorMessage!,
                          style: AppStyles.bodySmall.copyWith(
                            color: AppTheme.error600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                ElevatedButton.icon(
                  onPressed: dash.isAttendanceActionLoading
                      ? null
                      : dash.toggleClockStatus,
                  icon: dash.isAttendanceActionLoading
                      ? SizedBox(
                          width: 14.w,
                          height: 14.w,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.login_rounded, size: 18.sp),
                  label: Text('check_in'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warning800,
                    foregroundColor: AppTheme.baseWhite,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

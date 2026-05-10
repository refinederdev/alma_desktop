import 'dart:math';

import 'package:alma_desktop/core/theme/app_styles.dart';
import 'package:alma_desktop/core/theme/alma_tokens.dart';
import 'package:alma_desktop/core/theme/app_theme.dart';
import 'package:alma_desktop/features/main/domain/entities/attendance_weekly_stat.dart';
import 'package:alma_desktop/features/main/domain/entities/message_line_chart_data.dart';
import 'package:alma_desktop/features/main/presentation/controllers/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DashboardController>(
      builder: (c) {
        return Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DashboardHeader(
                isRefreshing: c.isRefreshing,
                onRefresh: () => c.loadDashboard(refresh: true),
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: _DashboardBody(controller: c),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.isRefreshing,
    required this.onRefresh,
  });

  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: context.alma.surfaceVariant,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.alma.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'general_overview'.tr,
              style: AppStyles.titleMedium.copyWith(
                color: context.alma.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: isRefreshing ? null : onRefresh,
            icon: isRefreshing
                ? SizedBox(
                    width: 14.w,
                    height: 14.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.refresh_rounded, size: 18.sp),
            label: Text('refresh'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandMain2_600,
              foregroundColor: AppTheme.baseWhite,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading && !controller.hasAnyData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage != null && !controller.hasAnyData) {
      return Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 420.w),
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: AppTheme.error25,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppTheme.error100),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: AppTheme.error600, size: 30.sp),
              SizedBox(height: 8.h),
              Text(
                controller.errorMessage!,
                style: AppStyles.bodyMedium.copyWith(color: AppTheme.error700),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10.h),
              ElevatedButton(
                onPressed: controller.loadDashboard,
                child: Text('retry'.tr),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.isAgent) ...[
            _AgentAttendanceCard(controller: controller),
            SizedBox(height: 14.h),
          ],
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: [
              _StatCard(
                title: 'total_deals'.tr,
                value: controller.dealsStats?.totalCount.toString() ?? '--',
                icon: Icons.pie_chart_rounded,
                color: AppTheme.brandMain2_600,
              ),
              _StatCard(
                title: 'opened_deals'.tr,
                value: controller.dealsStats?.openCount.toString() ?? '--',
                icon: Icons.folder_open_rounded,
                color: AppTheme.warning700,
              ),
              _StatCard(
                title: 'won_deals'.tr,
                value: controller.dealsStats?.wonCount.toString() ?? '--',
                icon: Icons.emoji_events_rounded,
                color: AppTheme.success700,
              ),
              _StatCard(
                title: 'lost_deals'.tr,
                value: controller.dealsStats?.lostCount.toString() ?? '--',
                icon: Icons.trending_down_rounded,
                color: AppTheme.error700,
              ),
              _StatCard(
                title: 'total_day'.tr,
                value: controller.todayTotal?.formattedTotalTime ?? '--',
                icon: Icons.today_rounded,
                color: AppTheme.brandMain700,
              ),
              _StatCard(
                title: 'this_week'.tr,
                value: controller.weekTotal?.formattedTotalTime ?? '--',
                icon: Icons.calendar_view_week_rounded,
                color: context.alma.onSurface,
              ),
            ],
          ),
          SizedBox(height: 14.h),
          _MessagesStatsCard(controller: controller),
          SizedBox(height: 14.h),
          _WeeklyAttendanceCard(data: controller.weeklyStats),
          SizedBox(height: 14.h),
          _MessagesTrendCard(data: controller.messageLineChart),
        ],
      ),
    );
  }
}

class _AgentAttendanceCard extends StatelessWidget {
  const _AgentAttendanceCard({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final statusLabel = controller.isClockedIn
        ? 'checked_in_now'.tr
        : 'not_clocked_in'.tr;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.alma.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.alma.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'track_working_time'.tr,
                  style: AppStyles.titleSmall.copyWith(
                    color: context.alma.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: controller.isAttendanceActionLoading
                    ? null
                    : controller.toggleClockStatus,
                icon: controller.isAttendanceActionLoading
                    ? SizedBox(
                        width: 14.w,
                        height: 14.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        controller.isClockedIn
                            ? Icons.logout_rounded
                            : Icons.login_rounded,
                        size: 18.sp,
                      ),
                label: Text(controller.isClockedIn ? 'check_out'.tr : 'check_in'.tr),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              _MiniStat(
                title: 'status'.tr,
                valueText: controller.isAttendanceLoading ? '...' : statusLabel,
              ),
              _MiniStat(
                title: 'current_session'.tr,
                valueText: controller.isClockedIn
                    ? controller.formattedSessionElapsed
                    : (controller.attendanceStatus?.formattedTotalTime ?? '--'),
              ),
            ],
          ),
          if (!controller.isClockedIn) ...[
            SizedBox(height: 8.h),
            Text(
              'clock_in_to_start_timer'.tr,
              style: AppStyles.bodySmall.copyWith(color: context.alma.onSurfaceTertiary),
            ),
          ],
          if (controller.attendanceErrorMessage != null) ...[
            SizedBox(height: 8.h),
            Text(
              controller.attendanceErrorMessage!,
              style: AppStyles.bodySmall.copyWith(color: AppTheme.error600),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250.w,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.alma.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.alma.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppStyles.bodySmall.copyWith(color: context.alma.onSurfaceTertiary),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: AppStyles.titleLarge.copyWith(
                    color: context.alma.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessagesStatsCard extends StatelessWidget {
  const _MessagesStatsCard({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final stats = controller.messageStats;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.alma.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.alma.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'messages_stats'.tr,
            style: AppStyles.titleSmall.copyWith(
              color: context.alma.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              _MiniStat(title: 'total_messages'.tr, value: stats?.totalMessages),
              _MiniStat(title: 'sent_messages'.tr, value: stats?.sent),
              _MiniStat(title: 'received_messages'.tr, value: stats?.received),
              _MiniStat(
                title: 'reply_rate'.tr,
                valueText: stats == null ? '--' : '${stats.replyRate}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.title, this.value, this.valueText});

  final String title;
  final int? value;
  final String? valueText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180.w,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: context.alma.surfaceVariant,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: context.alma.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppStyles.labelSmall.copyWith(color: context.alma.onSurfaceTertiary),
          ),
          SizedBox(height: 2.h),
          Text(
            valueText ?? (value?.toString() ?? '--'),
            style: AppStyles.titleMedium.copyWith(
              color: context.alma.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyAttendanceCard extends StatelessWidget {
  const _WeeklyAttendanceCard({required this.data});

  final List<AttendanceWeeklyStat> data;

  @override
  Widget build(BuildContext context) {
    final maxHours = data.isEmpty ? 0.0 : data.map((e) => e.hours).reduce(max);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.alma.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.alma.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'weekly_attendance'.tr,
            style: AppStyles.titleSmall.copyWith(
              color: context.alma.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10.h),
          if (data.isEmpty)
            Text(
              'no_data_available'.tr,
              style: AppStyles.bodySmall.copyWith(color: context.alma.onSurfaceTertiary),
            )
          else
            SizedBox(
              height: 140.h,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.map((item) {
                  final ratio = maxHours == 0 ? 0.0 : (item.hours / maxHours);
                  final barHeight = (ratio * 92.h).clamp(8.h, 92.h);
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            item.hours.toStringAsFixed(1),
                            style: AppStyles.labelSmall.copyWith(color: context.alma.onSurfaceSecondary),
                          ),
                          SizedBox(height: 6.h),
                          Container(
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: AppTheme.brandMain2_500,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            item.day,
                            style: AppStyles.labelSmall.copyWith(color: context.alma.onSurfaceTertiary),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessagesTrendCard extends StatelessWidget {
  const _MessagesTrendCard({required this.data});

  final List<MessageLineChartData> data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.alma.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.alma.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'messages_trend'.tr,
            style: AppStyles.titleSmall.copyWith(
              color: context.alma.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10.h),
          if (data.isEmpty)
            Text(
              'no_data_available'.tr,
              style: AppStyles.bodySmall.copyWith(color: context.alma.onSurfaceTertiary),
            )
          else
            ...data.take(7).map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  children: [
                    SizedBox(
                      width: 64.w,
                      child: Text(
                        '${item.date.day}/${item.date.month}',
                        style: AppStyles.labelSmall.copyWith(color: context.alma.onSurfaceSecondary),
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: _ratio(item.sent, item.received),
                        minHeight: 8.h,
                        borderRadius: BorderRadius.circular(12.r),
                        backgroundColor: context.alma.outline,
                        color: AppTheme.success500,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      '${item.sent}/${item.received}',
                      style: AppStyles.labelSmall.copyWith(color: context.alma.onSurfaceSecondary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _ratio(int sent, int received) {
    final total = sent + received;
    if (total <= 0) return 0;
    return sent / total;
  }
}

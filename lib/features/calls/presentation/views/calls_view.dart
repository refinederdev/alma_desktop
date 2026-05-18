import 'package:alma_desktop/core/theme/alma_tokens.dart';
import 'package:alma_desktop/core/theme/app_styles.dart';
import 'package:alma_desktop/core/theme/app_theme.dart';
import 'package:alma_desktop/features/calls/domain/entities/call_session.dart';
import 'package:alma_desktop/features/calls/domain/entities/whatsapp_call.dart';
import 'package:alma_desktop/features/calls/presentation/controllers/call_controller.dart';
import 'package:alma_desktop/features/calls/presentation/controllers/calls_history_controller.dart';
import 'package:alma_desktop/features/calls/presentation/widgets/outbound_dialer_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class CallsView extends GetView<CallsHistoryController> {
  const CallsView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CallsHistoryController>(
      builder: (c) {
        return GetBuilder<CallController>(
          builder: (cc) {
            return Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  _Header(historyController: c, callController: cc),
                  SizedBox(height: 14.h),
                  Expanded(child: _Body(controller: c, callController: cc)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.historyController,
    required this.callController,
  });

  final CallsHistoryController historyController;
  final CallController callController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.alma.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.alma.outline),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppTheme.brandMain2_100,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.call_rounded,
              color: AppTheme.brandMain2_600,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'calls'.tr,
                  style: AppStyles.titleMedium.copyWith(
                    color: context.alma.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    _StatusDot(
                      connected: callController.isReverbConnected,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      callController.isReverbConnected
                          ? 'realtime_connected'.tr
                          : 'realtime_disconnected'.tr,
                      style: AppStyles.labelSmall.copyWith(
                        color: context.alma.onSurfaceTertiary,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: context.alma.surfaceVariant,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'sessions_count'.trParams({
                          'count': '${callController.sessions.length}',
                        }),
                        style: AppStyles.labelSmall.copyWith(
                          color: context.alma.onSurfaceTertiary,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    InkWell(
                      borderRadius: BorderRadius.circular(8.r),
                      onTap: () async {
                        await callController.shutdown();
                        await callController.initialize();
                      },
                      child: Padding(
                        padding: EdgeInsets.all(4.w),
                        child: Icon(
                          Icons.refresh_rounded,
                          size: 14.sp,
                          color: context.alma.onSurfaceTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (callController.sessions.length > 1)
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: _SessionsDropdown(
                sessions: callController.sessions,
                selectedId: historyController.selectedSessionId,
                onChanged: (id) {
                  if (id != null) historyController.changeSession(id);
                },
              ),
            ),
          ElevatedButton.icon(
            onPressed: callController.sessions.isEmpty
                ? null
                : () {
                    Get.dialog(
                      OutboundDialerDialog(
                        initialSessionId: historyController.selectedSessionId,
                      ),
                    );
                  },
            icon: Icon(Icons.call_rounded, size: 18.sp),
            label: Text('make_call'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success500,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          IconButton(
            tooltip: 'refresh'.tr,
            onPressed: historyController.isRefreshing
                ? null
                : () => historyController.load(refresh: true),
            icon: historyController.isRefreshing
                ? SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.refresh_rounded, size: 20.sp),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8.w,
      height: 8.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: connected ? AppTheme.success500 : AppTheme.gray300,
      ),
    );
  }
}

class _SessionsDropdown extends StatelessWidget {
  const _SessionsDropdown({
    required this.sessions,
    required this.selectedId,
    required this.onChanged,
  });

  final List<CallSession> sessions;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: context.alma.inputFill,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: context.alma.outline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedId,
          items: sessions
              .map(
                (s) => DropdownMenuItem<int>(
                  value: s.id,
                  child: Text(
                    s.sessionName ?? (s.phoneNumber ?? 'session ${s.id}'),
                    style: AppStyles.bodySmall.copyWith(
                      color: context.alma.onSurface,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: context.alma.onSurfaceTertiary,
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.controller, required this.callController});

  final CallsHistoryController controller;
  final CallController callController;

  @override
  Widget build(BuildContext context) {
    if (callController.sessions.isEmpty) {
      return _EmptyState(
        icon: Icons.phone_disabled_rounded,
        title: 'no_call_session_available'.tr,
        message: 'no_call_session_hint'.tr,
      );
    }
    if (controller.isLoading && controller.calls.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.calls.isEmpty) {
      return _EmptyState(
        icon: Icons.call_end_outlined,
        title: 'no_calls_yet'.tr,
        message: 'no_calls_hint'.tr,
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: context.alma.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.alma.outline),
      ),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.extentAfter <= 160 && controller.hasMore) {
            controller.loadMore();
          }
          return false;
        },
        child: ListView.separated(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          itemCount: controller.calls.length + (controller.hasMore ? 1 : 0),
          separatorBuilder: (_, _) => Divider(
            height: 1.h,
            color: context.alma.outline,
          ),
          itemBuilder: (context, index) {
            if (index >= controller.calls.length) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            final call = controller.calls[index];
            return _CallTile(call: call);
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48.sp, color: context.alma.onSurfaceHint),
          SizedBox(height: 10.h),
          Text(
            title,
            style: AppStyles.titleMedium.copyWith(
              color: context.alma.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Text(
              message,
              style: AppStyles.bodySmall.copyWith(
                color: context.alma.onSurfaceTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _CallTile extends StatelessWidget {
  const _CallTile({required this.call});

  final WhatsAppCall call;

  @override
  Widget build(BuildContext context) {
    final isInbound = call.isInbound;
    final color = _statusColor(context, call.status);
    final icon = isInbound
        ? Icons.call_received_rounded
        : Icons.call_made_rounded;

    final name = (call.contactName?.trim().isNotEmpty == true)
        ? call.contactName!
        : (call.displayPhone ?? '—');
    final phone = call.displayPhone ?? '';
    final timeText = _formatTime(call.createdAt ?? call.startedAt);

    return InkWell(
      onTap: () {
        final cc = Get.find<CallController>();
        if (cc.hasActiveCall) return;
        Get.dialog(
          OutboundDialerDialog(
            initialPhone: call.displayPhone,
            initialSessionId: call.sessionId,
            contactName: call.contactName,
            dealId: call.dealId,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: color, size: 18.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppStyles.titleSmall.copyWith(
                      color: context.alma.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    [
                      _statusLabel(call.status),
                      if (phone.isNotEmpty) phone,
                    ].join(' • '),
                    style: AppStyles.bodySmall.copyWith(
                      color: context.alma.onSurfaceTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (call.duration != null && call.duration!.isNotEmpty)
                  Text(
                    call.duration!,
                    style: AppStyles.labelSmall.copyWith(
                      color: context.alma.onSurface,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                if (timeText != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    timeText,
                    style: AppStyles.labelSmall.copyWith(
                      color: context.alma.onSurfaceHint,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case 'completed':
        return AppTheme.success500;
      case 'rejected':
      case 'missed':
      case 'failed':
        return AppTheme.error500;
      case 'in_progress':
      case 'ringing':
        return AppTheme.brandMain2_500;
      default:
        return context.alma.onSurfaceTertiary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'call_status_completed'.tr;
      case 'rejected':
        return 'call_status_rejected'.tr;
      case 'missed':
        return 'call_status_missed'.tr;
      case 'failed':
        return 'call_status_failed'.tr;
      case 'in_progress':
        return 'call_status_in_progress'.tr;
      case 'ringing':
        return 'call_status_ringing'.tr;
      default:
        return status;
    }
  }

  String? _formatTime(DateTime? time) {
    if (time == null) return null;
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays == 0) {
      final h = time.hour.toString().padLeft(2, '0');
      final m = time.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    if (diff.inDays == 1) {
      return 'yesterday'.tr;
    }
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
  }
}

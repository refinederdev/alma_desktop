import 'dart:async';
import 'dart:io';

import 'package:alma_desktop/core/theme/app_styles.dart';
import 'package:alma_desktop/core/theme/alma_tokens.dart';
import 'package:alma_desktop/core/theme/app_theme.dart';
import 'package:alma_desktop/core/widgets/agent_check_in_status_banner.dart';
import 'package:alma_desktop/core/widgets/whatsapp_formatted_text.dart';
import 'package:alma_desktop/core/config/app_config.dart';
import 'package:alma_desktop/core/errors/app_messages.dart';
import 'package:alma_desktop/features/calls/presentation/controllers/call_controller.dart';
import 'package:alma_desktop/features/calls/presentation/widgets/outbound_dialer_dialog.dart';
import 'package:alma_desktop/features/main/domain/entities/deal.dart';
import 'package:alma_desktop/features/main/domain/entities/deal_message.dart';
import 'package:alma_desktop/features/global/presentation/controllers/global_controller.dart';
import 'package:alma_desktop/features/main/presentation/controllers/chat_controller.dart';
import 'package:alma_desktop/features/main/presentation/controllers/crm_kanban_controller.dart';
import 'package:alma_desktop/features/main/domain/entities/company_location.dart';
import 'package:dio/dio.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatView extends GetView<ChatController> {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatController>(
      builder: (c) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AgentCheckInStatusBanner(),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 370.w,
                        child: _ChatDealsPanel(controller: c),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(child: _ChatMessagesPanel(controller: c)),
                    ],
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

class _ChatDealsPanel extends StatelessWidget {
  const _ChatDealsPanel({required this.controller});

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = _isSuperAdminUser();
    return Container(
      decoration: BoxDecoration(
        color: context.alma.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.alma.outline),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'chat'.tr,
                  style: AppStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.alma.onSurface,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'total_deals_count'.trParams({
                    'count': controller.filteredDeals.length.toString(),
                  }),
                  style: AppStyles.bodySmall.copyWith(color: context.alma.onSurfaceTertiary),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: controller.onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'search_in_deals'.tr,
                          prefixIcon: Icon(Icons.search_rounded, size: 18.sp),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 10.h,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    IconButton(
                      tooltip: 'refresh'.tr,
                      onPressed: controller.isRefreshing
                          ? null
                          : () => controller.refreshAll(),
                      icon: controller.isRefreshing
                          ? SizedBox(
                              width: 16.w,
                              height: 16.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(Icons.refresh_rounded, size: 20.sp),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1.h, color: context.alma.outline),
          Expanded(
            child: controller.isLoadingDeals
                ? const Center(child: CircularProgressIndicator())
                : controller.filteredDeals.isEmpty
                ? Center(
                    child: Text(
                      'no_deals_found'.tr,
                      style: AppStyles.bodyMedium.copyWith(
                        color: context.alma.onSurfaceHint,
                      ),
                    ),
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.extentAfter <= 180 &&
                          controller.hasMoreDeals &&
                          !controller.isLoadingMoreDeals) {
                        controller.loadMoreDeals();
                      }
                      return false;
                    },
                    child: ListView.separated(
                      itemCount:
                          controller.filteredDeals.length +
                          ((controller.hasMoreDeals ||
                                  controller.isLoadingMoreDeals)
                              ? 1
                              : 0),
                      separatorBuilder: (_, _) =>
                          Divider(height: 1.h, color: context.alma.outline),
                      itemBuilder: (context, index) {
                        if (index >= controller.filteredDeals.length) {
                          if (controller.isLoadingMoreDeals) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }

                        final deal = controller.filteredDeals[index];
                        final isSelected =
                            controller.selectedDeal?.id == deal.id;
                        return _DealTile(
                          controller: controller,
                          deal: deal,
                          showAssignedAgent: isSuperAdmin,
                          isSelected: isSelected,
                          onTap: () => controller.selectDeal(deal),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DealTile extends StatelessWidget {
  const _DealTile({
    required this.controller,
    required this.deal,
    required this.showAssignedAgent,
    required this.isSelected,
    required this.onTap,
  });

  final ChatController controller;
  final Deal deal;
  final bool showAssignedAgent;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lastMessage = deal.lastMessage?.messageBody;
    final trailing = deal.lastMessage?.messageTimestamp ?? 0;
    final messageTime = trailing > 0
        ? DateTime.fromMillisecondsSinceEpoch(_normalizeUnixToMillis(trailing))
        : null;
    final hasUnread = controller.hasUnreadForDeal(deal.id);
    final unreadCount = controller.unreadCountForDeal(deal.id);
    final waitingReply = (deal.lastMessage?.fromMe ?? true) == false;
    final isNewDeal = controller.isNewDeal(deal.id);
    final assignedAgentName = _assignedAgentName(deal);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          color: isSelected
              ? AppTheme.brandMain2_100.withValues(alpha: 0.25)
              : null,
          child: Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: AppTheme.brandMain2_100,
                child: Text(
                  _initials(deal),
                  style: AppStyles.labelLarge.copyWith(
                    color: AppTheme.brandMain2_600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _safeText(
                        deal.contactName?.trim().isNotEmpty == true
                            ? deal.contactName!
                            : (deal.contactPhone ?? '—'),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.titleSmall.copyWith(
                        color: context.alma.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (showAssignedAgent && assignedAgentName != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        '${'agent'.tr}: ${_safeText(assignedAgentName)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.labelSmall.copyWith(
                          color: context.alma.onSurfaceTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    SizedBox(height: 2.h),
                    Text(
                      _safeText(
                        lastMessage?.trim().isNotEmpty == true
                            ? lastMessage!
                            : (deal.title ?? ''),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.bodySmall.copyWith(
                        color: hasUnread ? context.alma.onSurface : context.alma.onSurfaceHint,
                        fontWeight: hasUnread
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 6.h,
                      children: [
                        if (isNewDeal)
                          _DealInfoBadge(
                            label: 'new_deal_badge'.tr,
                            backgroundColor: AppTheme.error100,
                            foregroundColor: AppTheme.error700,
                          ),
                        if (waitingReply)
                          _DealInfoBadge(
                            label: 'waiting_for_reply_badge'.tr,
                            backgroundColor: AppTheme.error100,
                            foregroundColor: AppTheme.error700,
                          ),
                        if (hasUnread)
                          _DealInfoBadge(
                            label: unreadCount > 9 ? '9+' : '$unreadCount',
                            backgroundColor: AppTheme.error100,
                            foregroundColor: AppTheme.error700,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (messageTime != null)
                    Text(
                      _formatTime(messageTime),
                      style: AppStyles.labelSmall.copyWith(
                        color: context.alma.onSurfaceHint,
                      ),
                    ),
                  SizedBox(height: 4.h),
                  _DealStatusBadge(status: deal.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(Deal deal) {
    final name = _safeText(deal.contactName?.trim());
    if (name.isEmpty) return '#';
    final parts = name.split(' ').where((e) => e.trim().isNotEmpty).toList();
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _safeText(String? value) => _sanitizeInvalidUtf16(value ?? '');

  String _sanitizeInvalidUtf16(String input) {
    if (input.isEmpty) return input;
    final buffer = StringBuffer();
    for (var i = 0; i < input.length; i++) {
      final unit = input.codeUnitAt(i);
      final isHigh = unit >= 0xD800 && unit <= 0xDBFF;
      final isLow = unit >= 0xDC00 && unit <= 0xDFFF;

      if (isHigh) {
        if (i + 1 < input.length) {
          final next = input.codeUnitAt(i + 1);
          final nextIsLow = next >= 0xDC00 && next <= 0xDFFF;
          if (nextIsLow) {
            buffer.writeCharCode(unit);
            buffer.writeCharCode(next);
            i++;
            continue;
          }
        }
        buffer.writeCharCode(0xFFFD);
        continue;
      }

      if (isLow) {
        buffer.writeCharCode(0xFFFD);
        continue;
      }

      buffer.writeCharCode(unit);
    }
    return buffer.toString();
  }
}

class _DealStatusBadge extends StatelessWidget {
  const _DealStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    Color bg;
    Color fg;
    String label;

    switch (normalized) {
      case 'won':
        bg = context.alma.statusWonBg;
        fg = context.alma.statusWonFg;
        label = 'won'.tr;
        break;
      case 'lost':
        bg = context.alma.statusLostBg;
        fg = context.alma.statusLostFg;
        label = 'lost'.tr;
        break;
      default:
        bg = context.alma.statusOpenBg;
        fg = context.alma.statusOpenFg;
        label = 'open'.tr;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        label,
        style: AppStyles.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DealInfoBadge extends StatelessWidget {
  const _DealInfoBadge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        label,
        style: AppStyles.labelSmall.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ChatMessagesPanel extends StatelessWidget {
  const _ChatMessagesPanel({required this.controller});

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    final selectedDeal = controller.selectedDeal;
    return Container(
      decoration: BoxDecoration(
        color: context.alma.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.alma.outline),
      ),
      child: selectedDeal == null
          ? Center(
              child: Text(
                'select_chat_to_view_messages'.tr,
                style: AppStyles.bodyMedium.copyWith(color: context.alma.onSurfaceHint),
              ),
            )
          : Column(
              children: [
                _ChatHeader(deal: selectedDeal, controller: controller),
                Divider(height: 1.h, color: context.alma.outline),
                if (controller.showContactDealHistory) ...[
                  _FullCustomerHistoryBanner(controller: controller),
                  Divider(height: 1.h, color: context.alma.outline),
                ],
                Expanded(
                  child: controller.isLoadingMessages
                      ? const Center(child: CircularProgressIndicator())
                      : _MessagesList(controller: controller),
                ),
                Divider(height: 1.h, color: context.alma.outline),
                _Composer(controller: controller),
              ],
            ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.deal, required this.controller});

  final Deal deal;
  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = _isSuperAdminUser();
    final assignedAgentName = _assignedAgentName(deal);
    final secondaryText = isSuperAdmin
        ? (assignedAgentName ?? '-')
        : (deal.contactPhone ?? '');
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22.r,
            backgroundColor: AppTheme.brandMain2_100,
            child: Icon(
              Icons.chat_bubble_rounded,
              color: AppTheme.brandMain2_600,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sanitizeInvalidUtf16(
                    deal.contactName?.trim().isNotEmpty == true
                        ? deal.contactName!
                        : (deal.contactPhone ?? '-'),
                  ),
                  style: AppStyles.titleMedium.copyWith(
                    color: context.alma.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  isSuperAdmin
                      ? '${'agent'.tr}: ${_sanitizeInvalidUtf16(secondaryText)}'
                      : _sanitizeInvalidUtf16(secondaryText),
                  style: AppStyles.bodySmall.copyWith(color: context.alma.onSurfaceHint),
                ),
              ],
            ),
          ),
          SizedBox(width: 6.w),
          if (deal.contactPhone?.trim().isNotEmpty == true)
            _ChatCallButton(deal: deal),
          SizedBox(width: 6.w),
          PopupMenuButton<_ChatHeaderDealAction>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: context.alma.onSurfaceTertiary,
              size: 18.sp,
            ),
            color: context.alma.surface,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: BorderSide(color: context.alma.outline),
            ),
            position: PopupMenuPosition.under,
            tooltip: 'action'.tr,
            itemBuilder: (context) => [
              if (deal.contactPhone?.trim().isNotEmpty == true)
                PopupMenuItem<_ChatHeaderDealAction>(
                  value: _ChatHeaderDealAction.copyClientPhone,
                  child: Row(
                    children: [
                      Icon(
                        Icons.copy_rounded,
                        color: context.alma.onSurfaceSecondary,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'copy_client_phone'.tr,
                        style: AppStyles.labelLarge.copyWith(
                          color: context.alma.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              if (deal.contactPhone?.trim().isNotEmpty == true)
                PopupMenuItem<_ChatHeaderDealAction>(
                  value: _ChatHeaderDealAction.customerDealHistory,
                  child: Row(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        color: context.alma.onSurfaceSecondary,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'customer_deal_history'.tr,
                        style: AppStyles.labelLarge.copyWith(
                          color: context.alma.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              PopupMenuItem<_ChatHeaderDealAction>(
                value: _ChatHeaderDealAction.editDeal,
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      color: context.alma.onSurfaceSecondary,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'edit_deal'.tr,
                      style: AppStyles.labelLarge.copyWith(
                        color: context.alma.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<_ChatHeaderDealAction>(
                value: _ChatHeaderDealAction.transferDeal,
                child: Row(
                  children: [
                    Icon(
                      Icons.swap_horiz_rounded,
                      color: context.alma.onSurfaceSecondary,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'transfer_deal'.tr,
                      style: AppStyles.labelLarge.copyWith(
                        color: context.alma.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (action) async {
              final crmController = Get.find<CrmKanbanController>();
              switch (action) {
                case _ChatHeaderDealAction.copyClientPhone:
                  final phone = deal.contactPhone?.trim();
                  if (phone != null && phone.isNotEmpty) {
                    await Clipboard.setData(ClipboardData(text: phone));
                    AppMessages.showSnackBar(
                      type: ErrorType.success,
                      title: 'done'.tr,
                      message: 'client_phone_copied'.tr,
                    );
                  }
                  break;
                case _ChatHeaderDealAction.customerDealHistory:
                  if (controller.showContactDealHistory) {
                    await controller.hideContactDealHistoryPanel();
                  } else {
                    await controller.enableFullCustomerHistoryFromMenu();
                  }
                  break;
                case _ChatHeaderDealAction.editDeal:
                  await crmController.showEditDealDialog(deal);
                  break;
                case _ChatHeaderDealAction.transferDeal:
                  await crmController.showTransferDealDialog(deal);
                  break;
              }
              if (action != _ChatHeaderDealAction.copyClientPhone &&
                  action != _ChatHeaderDealAction.customerDealHistory) {
                await controller.refreshAll();
              }
            },
          ),
          SizedBox(width: 6.w),
          _DealStatusBadge(status: deal.status),
        ],
      ),
    );
  }
}

enum _ChatHeaderDealAction {
  copyClientPhone,
  customerDealHistory,
  editDeal,
  transferDeal,
}

class _ChatCallButton extends StatelessWidget {
  const _ChatCallButton({required this.deal});

  final Deal deal;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CallController>(
      builder: (cc) {
        final disabled = cc.sessions.isEmpty || cc.hasActiveCall;
        final color = disabled
            ? context.alma.onSurfaceHint
            : AppTheme.success500;
        return Tooltip(
          message: 'call_customer'.tr,
          child: Material(
            color: color.withValues(alpha: disabled ? 0.10 : 0.14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10.r),
              onTap: disabled
                  ? null
                  : () {
                      Get.dialog(
                        OutboundDialerDialog(
                          initialPhone: deal.contactPhone,
                          initialSessionId: deal.crmSessionId,
                          contactName: deal.contactName ?? deal.contactPhone,
                          dealId: deal.id,
                        ),
                      );
                    },
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 8.h,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.call_rounded, color: color, size: 16.sp),
                    SizedBox(width: 6.w),
                    Text(
                      'call'.tr,
                      style: AppStyles.labelMedium.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FullCustomerHistoryBanner extends StatelessWidget {
  const _FullCustomerHistoryBanner({required this.controller});

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.brandMain2_100.withValues(alpha: 0.45),
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 10.h, 6.w, 10.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.history_rounded,
              size: 18.sp,
              color: AppTheme.brandMain2_600,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'customer_deal_history'.tr,
                    style: AppStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.alma.onSurface,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'full_history_timeline_hint'.tr,
                    style: AppStyles.bodySmall.copyWith(
                      color: context.alma.onSurfaceSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'cancel'.tr,
              onPressed: () =>
                  unawaited(controller.hideContactDealHistoryPanel()),
              icon: Icon(Icons.close_rounded, size: 20.sp),
              color: context.alma.onSurfaceTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagesList extends StatelessWidget {
  const _MessagesList({required this.controller});

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.messages.isEmpty) {
      return Center(
        child: Text(
          'no_messages_yet'.tr,
          style: AppStyles.bodyMedium.copyWith(color: context.alma.onSurfaceHint),
        ),
      );
    }

    return ListView.builder(
      controller: controller.messagesScrollController,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      itemCount: controller.messages.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          if (controller.isLoadingOlderMessages) {
            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          if (controller.hasOlderMessages) {
            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: controller.loadOlderMessages,
                  icon: Icon(Icons.history_rounded, size: 16.sp),
                  label: Text('load_older_messages'.tr),
                ),
              ),
            );
          }

          return SizedBox(height: 4.h);
        }

        final message = controller.messages[i - 1];
        return _MessageBubble(message: message, controller: controller);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.controller});

  final DealMessage message;
  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    final isMe = message.fromMe;
    final text = message.messageBody?.trim();
    final hasText = text != null && text.isNotEmpty;
    final hasMedia =
        message.hasMediaContent && (message.mediaUrl?.isNotEmpty == true);
    final body = hasText ? text : (hasMedia ? '' : '...');
    final time = DateTime.fromMillisecondsSinceEpoch(
      _normalizeUnixToMillis(message.messageTimestamp),
    );
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');

    final canManageMessage = isMe;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 620.w),
          child: IntrinsicWidth(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.brandMain2_600 : context.alma.chatBubbleOtherBg,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isMe ? AppTheme.brandMain2_600 : context.alma.chatBubbleOtherBorder,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
            if (controller.showContactDealHistory &&
                message.sourceDeal != null &&
                message.sourceDeal!.id != controller.selectedDeal?.id) ...[
              Align(
                alignment:
                    isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 6.h),
                  child: Wrap(
                    spacing: 6.w,
                    runSpacing: 4.h,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'deal_id_label'
                            .trParams({'id': '${message.sourceDeal!.id}'}),
                        style: AppStyles.labelSmall.copyWith(
                          color: isMe
                              ? AppTheme.baseWhite.withValues(alpha: 0.9)
                              : context.alma.onSurfaceSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _DealStatusBadge(status: message.sourceDeal!.status),
                    ],
                  ),
                ),
              ),
            ],
            if (canManageMessage)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopupMenuButton<_MessageAction>(
                    tooltip: 'message_actions'.tr,
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      size: 18.sp,
                      color: isMe
                          ? AppTheme.baseWhite.withValues(alpha: 0.85)
                          : context.alma.onSurfaceTertiary,
                    ),
                    color: context.alma.surface,
                    onSelected: (action) async {
                      switch (action) {
                        case _MessageAction.edit:
                          controller.startEditingMessage(message);
                          break;
                        case _MessageAction.delete:
                          final confirmed = await Get.dialog<bool>(
                            AlertDialog(
                              title: Text('delete_message'.tr),
                              content: Text('confirm_delete_message'.tr),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(result: false),
                                  child: Text('cancel'.tr),
                                ),
                                TextButton(
                                  onPressed: () => Get.back(result: true),
                                  child: Text(
                                    'delete'.tr,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await controller.deleteMessage(message);
                          }
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<_MessageAction>(
                        value: _MessageAction.edit,
                        enabled:
                            (message.messageBody?.trim().isNotEmpty ?? false) &&
                            controller.deletingMessageId != message.id,
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18.sp),
                            SizedBox(width: 8.w),
                            Text('edit'.tr),
                          ],
                        ),
                      ),
                      PopupMenuItem<_MessageAction>(
                        value: _MessageAction.delete,
                        enabled: controller.deletingMessageId != message.id,
                        child: Row(
                          children: [
                            if (controller.deletingMessageId == message.id)
                              SizedBox(
                                width: 16.w,
                                height: 16.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              Icon(Icons.delete_outline, size: 18.sp),
                            SizedBox(width: 8.w),
                            Text('delete'.tr),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            if (hasMedia) ...[
              _MediaPreview(
                mediaUrl: message.mediaUrl!,
                mediaType: message.mediaType,
                fromMe: isMe,
              ),
              if (hasText) SizedBox(height: 8.h),
            ],
            if (hasText || (!hasText && !hasMedia))
              WhatsAppFormattedText(
                _sanitizeInvalidUtf16(body),
                textAlign: isMe ? TextAlign.end : TextAlign.start,
                style: AppStyles.bodyMedium.copyWith(
                  color: isMe ? AppTheme.baseWhite : context.alma.onSurface,
                ),
              ),
            SizedBox(height: 4.h),
            Text(
              '$hh:$mm',
              style: AppStyles.labelSmall.copyWith(
                color: isMe
                    ? AppTheme.baseWhite.withValues(alpha: 0.75)
                    : context.alma.onSurfaceHint,
              ),
            ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({
    required this.mediaUrl,
    required this.mediaType,
    required this.fromMe,
  });

  final String mediaUrl;
  final String? mediaType;
  final bool fromMe;

  bool get _isAudio {
    final type = (mediaType ?? '').toLowerCase();
    final url = mediaUrl.toLowerCase();
    return type.contains('audio') ||
        url.contains('.ogg') ||
        url.contains('.opus') ||
        url.contains('.mp3') ||
        url.contains('.wav') ||
        url.contains('.m4a');
  }

  bool get _isVideo {
    final type = (mediaType ?? '').toLowerCase();
    final url = mediaUrl.toLowerCase();
    return type.contains('video') ||
        url.contains('.mp4') ||
        url.contains('.mov') ||
        url.contains('.avi') ||
        url.contains('.mkv') ||
        url.contains('.webm');
  }

  bool get _isImage {
    final type = (mediaType ?? '').toLowerCase();
    return type.contains('image') ||
        mediaUrl.toLowerCase().contains('.jpg') ||
        mediaUrl.toLowerCase().contains('.jpeg') ||
        mediaUrl.toLowerCase().contains('.png') ||
        mediaUrl.toLowerCase().contains('.webp');
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolveUrl(mediaUrl);
    if (_isAudio) {
      return _AudioPreview(mediaUrl: resolvedUrl, fromMe: fromMe);
    }

    if (_isImage) {
      return GestureDetector(
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.black,
              child: InteractiveViewer(
                child: Image.network(
                  resolvedUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox(
                    height: 160,
                    child: Center(child: Icon(Icons.broken_image_rounded)),
                  ),
                ),
              ),
            ),
          );
        },
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: Image.network(
                resolvedUrl,
                width: 260.w,
                height: 180.h,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 260.w,
                  height: 110.h,
                  color: context.alma.mediaPlaceholderBg,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: context.alma.onSurfaceHint,
                    size: 28.sp,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 6.h,
              right: 6.w,
              child: _MediaDownloadButton(
                url: resolvedUrl,
                mediaType: mediaType,
                fromMe: fromMe,
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => _openMedia(resolvedUrl),
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: fromMe
              ? AppTheme.baseWhite.withValues(alpha: 0.15)
              : context.alma.outline,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isVideo
                  ? Icons.movie_creation_outlined
                  : Icons.description_outlined,
              size: 18.sp,
              color: fromMe ? AppTheme.baseWhite : context.alma.onSurfaceSecondary,
            ),
            SizedBox(width: 6.w),
            Text(
              _isVideo
                  ? 'Video attachment - tap to open'
                  : 'Document attachment - tap to open',
              style: AppStyles.labelMedium.copyWith(
                color: fromMe ? AppTheme.baseWhite : context.alma.onSurface,
              ),
            ),
            SizedBox(width: 8.w),
            _MediaDownloadButton(
              url: resolvedUrl,
              mediaType: mediaType,
              fromMe: fromMe,
            ),
          ],
        ),
      ),
    );
  }

  String _resolveUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final base = AppConfig.baseUrlWithoutApi;
    if (url.startsWith('/')) {
      return '$base$url';
    }
    return '$base/$url';
  }

  Future<void> _openMedia(String resolvedUrl) async {
    final uri = Uri.tryParse(resolvedUrl);
    if (uri == null) {
      AppMessages.showSnackBar(
        type: ErrorType.error,
        title: 'error'.tr,
        message: 'Invalid media URL.',
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      AppMessages.showSnackBar(
        type: ErrorType.error,
        title: 'error'.tr,
        message: 'Could not open this attachment.',
      );
    }
  }
}

class _AudioPreview extends StatefulWidget {
  const _AudioPreview({required this.mediaUrl, required this.fromMe});

  final String mediaUrl;
  final bool fromMe;

  @override
  State<_AudioPreview> createState() => _AudioPreviewState();
}

class _AudioPreviewState extends State<_AudioPreview> {
  AudioPlayer? _player;
  mk.Player? _windowsPlayer;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _windowsMediaOpened = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      _ensureWindowsPlayer();
    } else {
      _ensurePlayer();
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    _windowsPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foreground = widget.fromMe ? AppTheme.baseWhite : context.alma.onSurface;
    final background = widget.fromMe
        ? AppTheme.baseWhite.withValues(alpha: 0.15)
        : context.alma.outline;
    final progressMax = _duration.inMilliseconds > 0
        ? _duration.inMilliseconds.toDouble()
        : 1.0;
    final progressValue = _position.inMilliseconds
        .clamp(0, progressMax.toInt())
        .toDouble();

    return Container(
      width: 280.w,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(999.r),
            onTap: _isLoading ? null : _togglePlayback,
            child: Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.fromMe
                    ? AppTheme.baseWhite.withValues(alpha: 0.2)
                    : AppTheme.brandMain2_100,
              ),
              alignment: Alignment.center,
              child: _isLoading
                  ? SizedBox(
                      width: 14.w,
                      height: 14.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: foreground,
                      ),
                    )
                  : Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 20.sp,
                      color: widget.fromMe
                          ? AppTheme.baseWhite
                          : AppTheme.brandMain2_600,
                    ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2.4,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5.r),
                    overlayShape: SliderComponentShape.noOverlay,
                    activeTrackColor: widget.fromMe
                        ? AppTheme.baseWhite
                        : AppTheme.brandMain2_600,
                    inactiveTrackColor: foreground.withValues(alpha: 0.25),
                    thumbColor: widget.fromMe
                        ? AppTheme.baseWhite
                        : AppTheme.brandMain2_600,
                  ),
                  child: Slider(
                    min: 0,
                    max: progressMax,
                    value: progressValue,
                    onChanged: (value) async {
                      final target = Duration(milliseconds: value.toInt());
                      await _seekTo(target);
                    },
                  ),
                ),
                Text(
                  '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                  style: AppStyles.labelSmall.copyWith(color: foreground),
                ),
              ],
            ),
          ),
          SizedBox(width: 6.w),
          _MediaDownloadButton(
            url: widget.mediaUrl,
            mediaType: 'audio',
            fromMe: widget.fromMe,
          ),
        ],
      ),
    );
  }

  Future<void> _togglePlayback() async {
    if (Platform.isWindows) {
      await _toggleWindowsPlayback();
      return;
    }

    final player = _ensurePlayer();
    if (_isPlaying) {
      await player.pause();
      return;
    }

    setState(() => _isLoading = true);
    try {
      await player.play(UrlSource(widget.mediaUrl));
    } catch (_) {
      AppMessages.showSnackBar(
        type: ErrorType.error,
        title: 'error'.tr,
        message: 'Could not play this audio message.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleWindowsPlayback() async {
    final player = _ensureWindowsPlayer();
    if (_isPlaying) {
      await player.pause();
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (!_windowsMediaOpened) {
        await player.open(mk.Media(widget.mediaUrl), play: true);
        _windowsMediaOpened = true;
      } else {
        final isAtEnd =
            _duration.inMilliseconds > 0 &&
            _position.inMilliseconds >= (_duration.inMilliseconds - 500);
        if (isAtEnd) {
          await player.seek(Duration.zero);
        }
        await player.play();
      }
    } catch (_) {
      AppMessages.showSnackBar(
        type: ErrorType.error,
        title: 'error'.tr,
        message: 'Could not play this audio message.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _seekTo(Duration target) async {
    if (Platform.isWindows) {
      await _windowsPlayer?.seek(target);
      return;
    }
    await _player?.seek(target);
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  AudioPlayer _ensurePlayer() {
    final existing = _player;
    if (existing != null) return existing;

    final created = AudioPlayer();
    created.onDurationChanged.listen((duration) {
      if (!mounted) return;
      setState(() {
        _duration = duration;
      });
    });
    created.onPositionChanged.listen((position) {
      if (!mounted) return;
      setState(() {
        _position = position;
      });
    });
    created.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
    created.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });
    _player = created;
    return created;
  }

  mk.Player _ensureWindowsPlayer() {
    final existing = _windowsPlayer;
    if (existing != null) return existing;

    final created = mk.Player();
    created.stream.duration.listen((duration) {
      if (!mounted) return;
      setState(() => _duration = duration);
    });
    created.stream.position.listen((position) {
      if (!mounted) return;
      setState(() => _position = position);
    });
    created.stream.playing.listen((playing) {
      if (!mounted) return;
      setState(() => _isPlaying = playing);
    });
    created.stream.completed.listen((completed) {
      if (!mounted || !completed) return;
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });

    _windowsPlayer = created;
    return created;
  }
}

class _MediaDownloadButton extends StatefulWidget {
  const _MediaDownloadButton({
    required this.url,
    required this.mediaType,
    required this.fromMe,
  });

  final String url;
  final String? mediaType;
  final bool fromMe;

  @override
  State<_MediaDownloadButton> createState() => _MediaDownloadButtonState();
}

class _MediaDownloadButtonState extends State<_MediaDownloadButton> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'تحميل',
      visualDensity: VisualDensity.compact,
      onPressed: _isDownloading ? null : _download,
      icon: _isDownloading
          ? SizedBox(
              width: 14.w,
              height: 14.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: widget.fromMe ? AppTheme.baseWhite : context.alma.onSurface,
              ),
            )
          : Icon(
              Icons.download_rounded,
              size: 18.sp,
              color: widget.fromMe ? AppTheme.baseWhite : context.alma.onSurface,
            ),
    );
  }

  Future<void> _download() async {
    setState(() => _isDownloading = true);
    try {
      final savedPath = await _downloadMediaFile(
        url: widget.url,
        mediaType: widget.mediaType,
      );
      AppMessages.showSnackBar(
        type: ErrorType.success,
        title: 'done'.tr,
        message: 'تم تنزيل الملف بنجاح: $savedPath',
      );
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      AppMessages.showSnackBar(
        type: ErrorType.error,
        title: 'error'.tr,
        message: 'فشل تنزيل الملف: $message',
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }
}

Future<String> _downloadMediaFile({
  required String url,
  String? mediaType,
}) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    throw Exception('Invalid URL');
  }

  final downloadsDir = await _resolveDownloadsDirectory();
  final fileName = _buildDownloadFileName(uri: uri, mediaType: mediaType);
  final savePath = '${downloadsDir.path}${Platform.pathSeparator}$fileName';

  final token = GlobalController.to.token;
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 2),
      followRedirects: true,
      maxRedirects: 5,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Accept': '*/*',
      },
    ),
  );

  try {
    await dio.download(
      url,
      savePath,
      options: Options(
        responseType: ResponseType.bytes,
        receiveDataWhenStatusError: true,
      ),
    );
  } on DioException catch (e) {
    final status = e.response?.statusCode;
    final body = e.response?.data?.toString();
    if (status == 401 || status == 403) {
      throw Exception('غير مصرح بتحميل الملف ($status).');
    }
    if (status != null) {
      throw Exception(
        'فشل التحميل برمز HTTP $status${body != null ? ': $body' : ''}',
      );
    }
    throw Exception(e.message ?? 'حدث خطأ غير معروف أثناء التحميل.');
  }

  return savePath;
}

Future<Directory> _resolveDownloadsDirectory() async {
  final candidates = <Directory>[];

  if (Platform.isMacOS) {
    final macUserDownloads = await _macosRealUserDownloadsDirectory();
    if (macUserDownloads != null) {
      candidates.add(macUserDownloads);
    }
  }

  if (Platform.isLinux) {
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      candidates.add(Directory('$home${Platform.pathSeparator}Downloads'));
    }
  }

  if (Platform.isWindows) {
    final profile = Platform.environment['USERPROFILE'];
    if (profile != null && profile.isNotEmpty) {
      candidates.add(Directory('$profile${Platform.pathSeparator}Downloads'));
    }
  }

  try {
    final downloads = await getDownloadsDirectory();
    if (downloads != null) {
      candidates.add(downloads);
    }
  } catch (_) {}

  try {
    candidates.add(await getApplicationDocumentsDirectory());
  } catch (_) {}

  try {
    candidates.add(await getTemporaryDirectory());
  } catch (_) {}

  for (final dir in candidates) {
    if (await _ensureWritableDirectory(dir)) {
      return dir;
    }
  }

  return Directory.systemTemp;
}

Future<Directory?> _macosRealUserDownloadsDirectory() async {
  try {
    final result = await Process.run('whoami', const <String>[]);
    final username = (result.stdout as String).trim();
    if (username.isEmpty) return null;
    return Directory('/Users/$username/Downloads');
  } catch (_) {
    return null;
  }
}

Future<bool> _ensureWritableDirectory(Directory dir) async {
  try {
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final probe = File(
      '${dir.path}${Platform.pathSeparator}.alma_write_probe_${DateTime.now().microsecondsSinceEpoch}',
    );
    await probe.writeAsString('ok', flush: true);
    if (probe.existsSync()) {
      await probe.delete();
    }
    return true;
  } catch (_) {
    return false;
  }
}

String _buildDownloadFileName({required Uri uri, String? mediaType}) {
  final lastSegment = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
  var sanitized = lastSegment.split('?').first.trim();
  sanitized = sanitized.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

  if (sanitized.isNotEmpty) {
    return sanitized;
  }

  final now = DateTime.now().millisecondsSinceEpoch;
  final ext = _extensionFromMediaType(mediaType);
  return 'attachment_$now$ext';
}

String _extensionFromMediaType(String? mediaType) {
  final type = (mediaType ?? '').toLowerCase();
  if (type.contains('image')) return '.jpg';
  if (type.contains('audio')) return '.mp3';
  if (type.contains('video')) return '.mp4';
  if (type.contains('pdf')) return '.pdf';
  return '.bin';
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller});

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    final disabled = controller.selectedDeal?.isOpen != true;
    final isEditing = controller.editingMessage != null;
    final hasAttachment = controller.selectedAttachments.isNotEmpty;

    return Padding(
      padding: EdgeInsets.all(12.w),
      child: Column(
        children: [
          if (isEditing)
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: context.alma.warningBannerBg,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: context.alma.warningBannerBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    color: context.alma.warningBannerBody,
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'editing_message_mode'.tr,
                      style: AppStyles.bodySmall.copyWith(
                        color: context.alma.warningBannerTitle,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: controller.cancelEditingMessage,
                    child: Text('cancel'.tr),
                  ),
                ],
              ),
            ),
          if (hasAttachment)
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: context.alma.surfaceVariant,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: context.alma.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${controller.selectedAttachments.length} ملف محدد',
                    style: AppStyles.bodySmall.copyWith(
                      color: context.alma.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  ...List.generate(controller.selectedAttachments.length, (
                    index,
                  ) {
                    final file = controller.selectedAttachments[index];
                    final isImage = controller.isImageAttachment(file);
                    return Container(
                      margin: EdgeInsets.only(
                        bottom:
                            index == controller.selectedAttachments.length - 1
                            ? 0
                            : 6.h,
                      ),
                      child: Row(
                        children: [
                          if (isImage)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: Image.file(
                                file,
                                width: 48.w,
                                height: 48.w,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 48.w,
                                  height: 48.w,
                                  color: context.alma.outline,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.broken_image_rounded,
                                    color: context.alma.onSurfaceHint,
                                    size: 18.sp,
                                  ),
                                ),
                              ),
                            )
                          else
                            Icon(Icons.attach_file_rounded, size: 18.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              file.path.split('/').last,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppStyles.bodySmall.copyWith(
                                color: context.alma.onSurface,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                controller.removeAttachmentAt(index),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: controller.clearAttachment,
                      child: Text('إزالة الكل'),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                tooltip: 'Emoji',
                onPressed: disabled ? null : controller.toggleEmojiPicker,
                icon: Icon(Icons.emoji_emotions_outlined, size: 20.sp),
              ),
              IconButton(
                tooltip: 'إرسال موقع فرع',
                onPressed: disabled
                    ? null
                    : () => _openCompanyLocationsPicker(context, controller),
                icon: Icon(Icons.location_on_outlined, size: 20.sp),
              ),
              IconButton(
                tooltip: 'Media',
                onPressed: disabled
                    ? null
                    : () => _openAttachmentPicker(context, controller),
                icon: Icon(Icons.image_outlined, size: 20.sp),
              ),
              IconButton(
                tooltip: 'Paste image',
                onPressed: disabled ? null : controller.pickImageFromClipboard,
                icon: Icon(Icons.content_paste_rounded, size: 20.sp),
              ),
              IconButton(
                tooltip: 'File',
                onPressed: disabled ? null : controller.pickDocumentAttachment,
                icon: Icon(Icons.attach_file_rounded, size: 20.sp),
              ),
              Expanded(
                child: Focus(
                  onKeyEvent: (node, event) {
                    if (event is! KeyDownEvent) return KeyEventResult.ignored;

                    // Do not handle Ctrl/Cmd+V here: on Windows, reading the
                    // clipboard for images (Pasteboard.image) races with the
                    // text field's normal paste and can block pasting text.

                    final isEnterKey =
                        event.logicalKey == LogicalKeyboardKey.enter ||
                        event.logicalKey == LogicalKeyboardKey.numpadEnter;
                    if (!isEnterKey) return KeyEventResult.ignored;

                    if (HardwareKeyboard.instance.isShiftPressed) {
                      return KeyEventResult.ignored;
                    }

                    if (!disabled && !controller.isSendingMessage) {
                      controller.sendCurrentMessage();
                    }
                    return KeyEventResult.handled;
                  },
                  child: TextField(
                    controller: controller.messageController,
                    minLines: 1,
                    maxLines: 4,
                    enabled: !disabled,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    onTap: controller.hideEmojiPicker,
                    decoration: InputDecoration(
                      hintText: disabled
                          ? 'deal_closed_cannot_send'.tr
                          : 'write_your_message'.tr,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              ElevatedButton(
                onPressed:
                    disabled ||
                        controller.isSendingMessage ||
                        controller.isUpdatingMessage
                    ? null
                    : controller.sendCurrentMessage,
                child:
                    (controller.isSendingMessage ||
                        controller.isUpdatingMessage)
                    ? SizedBox(
                        width: 14.w,
                        height: 14.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        isEditing ? Icons.check_rounded : Icons.send_rounded,
                        size: 18.sp,
                      ),
              ),
            ],
          ),
          if (controller.showEmojiPicker && !disabled)
            _EmojiPickerPanel(onEmojiTap: controller.addEmoji),
        ],
      ),
    );
  }
}

enum _MessageAction { edit, delete }

class _EmojiPickerPanel extends StatelessWidget {
  const _EmojiPickerPanel({required this.onEmojiTap});

  final void Function(String emoji) onEmojiTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.all(8.w),
      height: 280.h,
      decoration: BoxDecoration(
        color: context.alma.surfaceVariant,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: context.alma.outline),
      ),
      child: EmojiPicker(
        onEmojiSelected: (_, emoji) => onEmojiTap(emoji.emoji),
        textEditingController: null,
        config: Config(
          height: 260.h,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(
            emojiSizeMax: 24.sp,
            columns: 9,
            verticalSpacing: 6,
            horizontalSpacing: 6,
            backgroundColor: context.alma.surfaceVariant,
          ),
          categoryViewConfig: CategoryViewConfig(
            backgroundColor: context.alma.surfaceVariant,
            indicatorColor: AppTheme.brandMain2_600,
            iconColorSelected: AppTheme.brandMain2_600,
            iconColor: context.alma.onSurfaceHint,
          ),
          bottomActionBarConfig: BottomActionBarConfig(
            backgroundColor: context.alma.surfaceVariant,
            buttonIconColor: context.alma.onSurface,
          ),
          skinToneConfig: const SkinToneConfig(enabled: true),
          searchViewConfig: SearchViewConfig(
            backgroundColor: context.alma.surfaceVariant,
            hintText: 'Search emoji',
          ),
        ),
      ),
    );
  }
}

Future<void> _openAttachmentPicker(
  BuildContext context,
  ChatController controller,
) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.alma.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
    ),
    builder: (_) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AttachmentTile(
                icon: Icons.image_rounded,
                label: 'Image',
                onTap: () {
                  Get.back();
                  controller.pickImageAttachment();
                },
              ),
              _AttachmentTile(
                icon: Icons.videocam_rounded,
                label: 'Video',
                onTap: () {
                  Get.back();
                  controller.pickVideoAttachment();
                },
              ),
              _AttachmentTile(
                icon: Icons.music_note_rounded,
                label: 'Audio',
                onTap: () {
                  Get.back();
                  controller.pickAudioAttachment();
                },
              ),
              _AttachmentTile(
                icon: Icons.attach_file_rounded,
                label: 'Document',
                onTap: () {
                  Get.back();
                  controller.pickDocumentAttachment();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppTheme.brandMain2_600),
      title: Text(
        label,
        style: AppStyles.titleSmall.copyWith(color: context.alma.onSurface),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: context.alma.onSurfaceHint),
    );
  }
}

Future<void> _openCompanyLocationsPicker(
  BuildContext context,
  ChatController controller,
) async {
  await controller.loadCompanyLocations();
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.alma.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
    ),
    builder: (_) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: SizedBox(
            height: 420.h,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'اختر فرعاً لإرسال موقعه',
                        style: AppStyles.titleSmall.copyWith(
                          color: context.alma.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'تحديث',
                      onPressed: controller.isLoadingCompanyLocations
                          ? null
                          : () => controller.loadCompanyLocations(force: true),
                      icon: controller.isLoadingCompanyLocations
                          ? SizedBox(
                              width: 16.w,
                              height: 16.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(Icons.refresh_rounded, size: 18.sp),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Expanded(
                  child: controller.isLoadingCompanyLocations
                      ? const Center(child: CircularProgressIndicator())
                      : controller.companyLocations.isEmpty
                      ? Center(
                          child: Text(
                            controller.companyLocationsErrorMessage ??
                                'لا توجد فروع.',
                            style: AppStyles.bodyMedium.copyWith(
                              color: context.alma.onSurfaceHint,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: controller.companyLocations.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1.h,
                            color: context.alma.outline,
                          ),
                          itemBuilder: (context, index) {
                            final CompanyLocation loc =
                                controller.companyLocations[index];
                            return ListTile(
                              leading: Icon(
                                Icons.location_on_rounded,
                                color: AppTheme.brandMain2_600,
                              ),
                              title: Text(
                                loc.name,
                                style: AppStyles.titleSmall.copyWith(
                                  color: context.alma.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: (loc.address != null &&
                                      loc.address!.trim().isNotEmpty)
                                  ? Text(
                                      loc.address!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppStyles.bodySmall.copyWith(
                                        color: context.alma.onSurfaceTertiary,
                                      ),
                                    )
                                  : null,
                              onTap: () async {
                                Get.back();
                                await controller.sendLocationMessage(loc.id);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

String _sanitizeInvalidUtf16(String input) {
  if (input.isEmpty) return input;
  final buffer = StringBuffer();
  for (var i = 0; i < input.length; i++) {
    final unit = input.codeUnitAt(i);
    final isHigh = unit >= 0xD800 && unit <= 0xDBFF;
    final isLow = unit >= 0xDC00 && unit <= 0xDFFF;

    if (isHigh) {
      if (i + 1 < input.length) {
        final next = input.codeUnitAt(i + 1);
        final nextIsLow = next >= 0xDC00 && next <= 0xDFFF;
        if (nextIsLow) {
          buffer.writeCharCode(unit);
          buffer.writeCharCode(next);
          i++;
          continue;
        }
      }
      buffer.writeCharCode(0xFFFD);
      continue;
    }

    if (isLow) {
      buffer.writeCharCode(0xFFFD);
      continue;
    }

    buffer.writeCharCode(unit);
  }
  return buffer.toString();
}

int _normalizeUnixToMillis(int rawTimestamp) {
  if (rawTimestamp <= 0) return 0;
  // Some backends return seconds while others return milliseconds.
  return rawTimestamp >= 1000000000000 ? rawTimestamp : rawTimestamp * 1000;
}

bool _isSuperAdminUser() {
  final roles = GlobalController.to.user?.roles ?? const <String>[];
  return roles.any((role) => role.toLowerCase().trim() == 'super_admin');
}

String? _assignedAgentName(Deal deal) {
  final fullName = deal.user?.fullName.trim();
  if (fullName != null && fullName.isNotEmpty) return fullName;
  final first = deal.user?.firstName.trim() ?? '';
  final last = deal.user?.lastName.trim() ?? '';
  final combined = '$first $last'.trim();
  if (combined.isNotEmpty) return combined;
  return null;
}

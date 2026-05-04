import 'package:alma_desktop/core/theme/app_styles.dart';
import 'package:alma_desktop/core/theme/app_theme.dart';
import 'package:alma_desktop/core/widgets/whatsapp_formatted_text.dart';
import 'package:alma_desktop/core/config/app_config.dart';
import 'package:alma_desktop/features/main/domain/entities/deal.dart';
import 'package:alma_desktop/features/main/domain/entities/deal_message.dart';
import 'package:alma_desktop/features/main/presentation/controllers/chat_controller.dart';
import 'package:alma_desktop/features/main/presentation/controllers/crm_kanban_controller.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ChatView extends GetView<ChatController> {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatController>(
      builder: (c) {
        return Padding(
          padding: EdgeInsets.all(20.w),
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
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.baseWhite,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.gray50),
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
                    color: AppTheme.gray800,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'total_deals_count'.trParams({
                    'count': controller.filteredDeals.length.toString(),
                  }),
                  style: AppStyles.bodySmall.copyWith(color: AppTheme.gray400),
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
          Divider(height: 1.h, color: AppTheme.gray50),
          Expanded(
            child: controller.isLoadingDeals
                ? const Center(child: CircularProgressIndicator())
                : controller.filteredDeals.isEmpty
                ? Center(
                    child: Text(
                      'no_deals_found'.tr,
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppTheme.gray300,
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
                      itemCount: controller.filteredDeals.length +
                          ((controller.hasMoreDeals || controller.isLoadingMoreDeals)
                              ? 1
                              : 0),
                      separatorBuilder: (_, _) =>
                          Divider(height: 1.h, color: AppTheme.gray50),
                      itemBuilder: (context, index) {
                        if (index >= controller.filteredDeals.length) {
                          if (controller.isLoadingMoreDeals) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }

                        final deal = controller.filteredDeals[index];
                        final isSelected = controller.selectedDeal?.id == deal.id;
                        return _DealTile(
                          deal: deal,
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
    required this.deal,
    required this.isSelected,
    required this.onTap,
  });

  final Deal deal;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lastMessage = deal.lastMessage?.messageBody;
    final trailing = deal.lastMessage?.messageTimestamp ?? 0;
    final messageTime = trailing > 0
        ? DateTime.fromMillisecondsSinceEpoch(trailing * 1000)
        : null;

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
                        color: AppTheme.gray700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                        color: AppTheme.gray300,
                      ),
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
                        color: AppTheme.gray300,
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
        bg = AppTheme.success50;
        fg = AppTheme.success800;
        label = 'won'.tr;
        break;
      case 'lost':
        bg = AppTheme.error50;
        fg = AppTheme.error800;
        label = 'lost'.tr;
        break;
      default:
        bg = AppTheme.warning50;
        fg = AppTheme.warning800;
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

class _ChatMessagesPanel extends StatelessWidget {
  const _ChatMessagesPanel({required this.controller});

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    final selectedDeal = controller.selectedDeal;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.baseWhite,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.gray50),
      ),
      child: selectedDeal == null
          ? Center(
              child: Text(
                'select_chat_to_view_messages'.tr,
                style: AppStyles.bodyMedium.copyWith(color: AppTheme.gray300),
              ),
            )
          : Column(
              children: [
                _ChatHeader(deal: selectedDeal, controller: controller),
                Divider(height: 1.h, color: AppTheme.gray50),
                Expanded(
                  child: controller.isLoadingMessages
                      ? const Center(child: CircularProgressIndicator())
                      : _MessagesList(controller: controller),
                ),
                Divider(height: 1.h, color: AppTheme.gray50),
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
                    color: AppTheme.gray800,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _sanitizeInvalidUtf16(deal.contactPhone ?? ''),
                  style: AppStyles.bodySmall.copyWith(color: AppTheme.gray300),
                ),
              ],
            ),
          ),
          SizedBox(width: 6.w),
          PopupMenuButton<_ChatHeaderDealAction>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: AppTheme.gray400,
              size: 18.sp,
            ),
            color: AppTheme.baseWhite,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: const BorderSide(color: AppTheme.gray50),
            ),
            position: PopupMenuPosition.under,
            tooltip: 'action'.tr,
            itemBuilder: (context) => [
              PopupMenuItem<_ChatHeaderDealAction>(
                value: _ChatHeaderDealAction.editDeal,
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      color: AppTheme.gray500,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'edit_deal'.tr,
                      style: AppStyles.labelLarge.copyWith(
                        color: AppTheme.gray700,
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
                      color: AppTheme.gray500,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'transfer_deal'.tr,
                      style: AppStyles.labelLarge.copyWith(
                        color: AppTheme.gray700,
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
                case _ChatHeaderDealAction.editDeal:
                  await crmController.showEditDealDialog(deal);
                  break;
                case _ChatHeaderDealAction.transferDeal:
                  await crmController.showTransferDealDialog(deal);
                  break;
              }
              await controller.refreshAll();
            },
          ),
          SizedBox(width: 6.w),
          _DealStatusBadge(status: deal.status),
        ],
      ),
    );
  }
}

enum _ChatHeaderDealAction { editDeal, transferDeal }

class _MessagesList extends StatelessWidget {
  const _MessagesList({required this.controller});

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.messages.isEmpty) {
      return Center(
        child: Text(
          'no_messages_yet'.tr,
          style: AppStyles.bodyMedium.copyWith(color: AppTheme.gray300),
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
        return _MessageBubble(message: message);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final DealMessage message;

  @override
  Widget build(BuildContext context) {
    final isMe = message.fromMe;
    final text = message.messageBody?.trim();
    final hasText = text != null && text.isNotEmpty;
    final hasMedia =
        message.hasMediaContent && (message.mediaUrl?.isNotEmpty == true);
    final body = hasText ? text : (hasMedia ? '' : '...');
    final time = DateTime.fromMillisecondsSinceEpoch(
      message.messageTimestamp * 1000,
    );
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        constraints: BoxConstraints(maxWidth: 620.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.brandMain2_600 : AppTheme.gray25,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isMe ? AppTheme.brandMain2_600 : AppTheme.gray50,
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
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
                style: AppStyles.bodyMedium.copyWith(
                  color: isMe ? AppTheme.baseWhite : AppTheme.gray700,
                ),
              ),
            SizedBox(height: 4.h),
            Text(
              '$hh:$mm',
              style: AppStyles.labelSmall.copyWith(
                color: isMe
                    ? AppTheme.baseWhite.withValues(alpha: 0.75)
                    : AppTheme.gray300,
              ),
            ),
          ],
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: Image.network(
            resolvedUrl,
            width: 260.w,
            height: 180.h,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 260.w,
              height: 110.h,
              color: AppTheme.gray50,
              alignment: Alignment.center,
              child: Icon(
                Icons.broken_image_rounded,
                color: AppTheme.gray300,
                size: 28.sp,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: fromMe
            ? AppTheme.baseWhite.withValues(alpha: 0.15)
            : AppTheme.gray50,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.attach_file_rounded,
            size: 18.sp,
            color: fromMe ? AppTheme.baseWhite : AppTheme.gray500,
          ),
          SizedBox(width: 6.w),
          Text(
            'Media attachment',
            style: AppStyles.labelMedium.copyWith(
              color: fromMe ? AppTheme.baseWhite : AppTheme.gray600,
            ),
          ),
        ],
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
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller});

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    final disabled = controller.selectedDeal?.isOpen != true;
    final hasAttachment = controller.selectedAttachment != null;

    return Padding(
      padding: EdgeInsets.all(12.w),
      child: Column(
        children: [
          if (hasAttachment)
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppTheme.gray25,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppTheme.gray50),
              ),
              child: Row(
                children: [
                  Icon(Icons.attach_file_rounded, size: 18.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      controller.selectedAttachment!.path.split('/').last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.bodySmall.copyWith(
                        color: AppTheme.gray600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: controller.clearAttachment,
                    icon: const Icon(Icons.close_rounded),
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
                tooltip: 'Media',
                onPressed: disabled
                    ? null
                    : () => _openAttachmentPicker(context, controller),
                icon: Icon(Icons.image_outlined, size: 20.sp),
              ),
              IconButton(
                tooltip: 'File',
                onPressed: disabled ? null : controller.pickDocumentAttachment,
                icon: Icon(Icons.attach_file_rounded, size: 20.sp),
              ),
              Expanded(
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
              SizedBox(width: 10.w),
              ElevatedButton(
                onPressed: disabled || controller.isSendingMessage
                    ? null
                    : controller.sendCurrentMessage,
                child: controller.isSendingMessage
                    ? SizedBox(
                        width: 14.w,
                        height: 14.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.send_rounded, size: 18.sp),
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
        color: AppTheme.gray25,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppTheme.gray50),
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
            backgroundColor: AppTheme.gray25,
          ),
          categoryViewConfig: CategoryViewConfig(
            backgroundColor: AppTheme.gray25,
            indicatorColor: AppTheme.brandMain2_600,
            iconColorSelected: AppTheme.brandMain2_600,
            iconColor: AppTheme.gray300,
          ),
          bottomActionBarConfig: BottomActionBarConfig(
            backgroundColor: AppTheme.gray25,
            buttonIconColor: AppTheme.baseWhite,
          ),
          skinToneConfig: const SkinToneConfig(enabled: true),
          searchViewConfig: SearchViewConfig(
            backgroundColor: AppTheme.gray25,
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
    backgroundColor: AppTheme.baseWhite,
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
        style: AppStyles.titleSmall.copyWith(color: AppTheme.gray700),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.gray300),
    );
  }
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

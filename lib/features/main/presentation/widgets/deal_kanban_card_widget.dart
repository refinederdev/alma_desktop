import 'package:alma_desktop/core/theme/app_styles.dart';
import 'package:alma_desktop/core/theme/app_theme.dart';
import 'package:alma_desktop/features/global/presentation/controllers/global_controller.dart';
import 'package:alma_desktop/features/main/domain/entities/deal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class DealKanbanCardWidget extends StatelessWidget {
  const DealKanbanCardWidget({
    super.key,
    required this.deal,
    this.isDragging = false,
    this.isBusy = false,
    this.onOpenChat,
    this.onEditDeal,
    this.onTransferDeal,
  });

  final Deal deal;
  final bool isDragging;
  final bool isBusy;
  final Future<void> Function(Deal deal)? onOpenChat;
  final Future<void> Function(Deal deal)? onEditDeal;
  final Future<void> Function(Deal deal)? onTransferDeal;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDragging ? 0.32 : 1,
      child: Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppTheme.baseWhite,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.gray50),
        boxShadow: isDragging ? AppTheme.shadowSM : AppTheme.shadowXS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  deal.title?.trim().isNotEmpty == true ? deal.title! : 'deal'.tr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.titleSmall.copyWith(
                    color: AppTheme.gray800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isBusy) ...[
                SizedBox(width: 8.w),
                SizedBox(
                  width: 14.w,
                  height: 14.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              ] else ...[
                SizedBox(width: 6.w),
                PopupMenuButton<_DealAction>(
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
                    PopupMenuItem<_DealAction>(
                      value: _DealAction.openChat,
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: AppTheme.gray500,
                            size: 18.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'open_chat'.tr,
                            style: AppStyles.labelLarge.copyWith(
                              color: AppTheme.gray700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<_DealAction>(
                      value: _DealAction.editDeal,
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
                    PopupMenuItem<_DealAction>(
                      value: _DealAction.transferDeal,
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
                    switch (action) {
                      case _DealAction.openChat:
                        await onOpenChat?.call(deal);
                        break;
                      case _DealAction.editDeal:
                        await onEditDeal?.call(deal);
                        break;
                      case _DealAction.transferDeal:
                        await onTransferDeal?.call(deal);
                        break;
                    }
                  },
                ),
              ],
            ],
          ),
          SizedBox(height: 8.h),
          _InfoRow(
            icon: Icons.person_outline_rounded,
            text: deal.contactName?.trim().isNotEmpty == true
                ? deal.contactName!
                : '-',
          ),
          SizedBox(height: 6.h),
          _InfoRow(
            icon: Icons.phone_outlined,
            text: deal.contactPhone?.trim().isNotEmpty == true
                ? deal.contactPhone!
                : '-',
          ),
          if (_isSuperAdminUser()) ...[
            SizedBox(height: 6.h),
            _InfoRow(
              icon: Icons.support_agent_rounded,
              text: _assignedAgentName(deal) ?? '-',
            ),
          ],
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _Badge(
                  color: AppTheme.brandMain2_100,
                  textColor: AppTheme.brandMain2_600,
                  text: deal.status,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '#${deal.id}',
                style: AppStyles.labelMedium.copyWith(color: AppTheme.gray400),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}

class DealKanbanDraggableCard extends StatelessWidget {
  const DealKanbanDraggableCard({
    super.key,
    required this.deal,
    this.isBusy = false,
    this.onOpenChat,
    this.onEditDeal,
    this.onTransferDeal,
  });

  final Deal deal;
  final bool isBusy;
  final Future<void> Function(Deal deal)? onOpenChat;
  final Future<void> Function(Deal deal)? onEditDeal;
  final Future<void> Function(Deal deal)? onTransferDeal;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<Deal>(
      data: deal,
      delay: const Duration(milliseconds: 120),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 300.w,
          child: DealKanbanCardWidget(
            deal: deal,
            onOpenChat: onOpenChat,
            onEditDeal: onEditDeal,
            onTransferDeal: onTransferDeal,
          ),
        ),
      ),
      childWhenDragging: DealKanbanCardWidget(
        deal: deal,
        isDragging: true,
        isBusy: isBusy,
        onOpenChat: onOpenChat,
        onEditDeal: onEditDeal,
        onTransferDeal: onTransferDeal,
      ),
      child: DealKanbanCardWidget(
        deal: deal,
        isBusy: isBusy,
        onOpenChat: onOpenChat,
        onEditDeal: onEditDeal,
        onTransferDeal: onTransferDeal,
      ),
    );
  }
}

enum _DealAction { openChat, editDeal, transferDeal }

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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: AppTheme.gray300),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppStyles.bodySmall.copyWith(color: AppTheme.gray500),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.color,
    required this.textColor,
    required this.text,
  });

  final Color color;
  final Color textColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppStyles.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

import 'package:alma_desktop/core/theme/app_styles.dart';
import 'package:alma_desktop/core/theme/alma_tokens.dart';
import 'package:alma_desktop/core/theme/app_theme.dart';
import 'package:alma_desktop/features/main/domain/entities/deal.dart';
import 'package:alma_desktop/features/main/presentation/controllers/crm_kanban_controller.dart';
import 'package:alma_desktop/features/main/presentation/widgets/deal_kanban_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class KanbanColumnWidget extends StatelessWidget {
  const KanbanColumnWidget({
    super.key,
    required this.title,
    required this.counter,
    required this.deals,
    required this.headerColor,
    required this.headerTextColor,
    required this.emptyMessage,
    required this.status,
    required this.onDealDropped,
    required this.isDealUpdating,
    required this.onOpenChat,
    required this.onEditDeal,
    required this.onTransferDeal,
    required this.onLoadMore,
    required this.hasMore,
    required this.isLoadingMore,
  });

  final String title;
  final int counter;
  final List<Deal> deals;
  final Color headerColor;
  final Color headerTextColor;
  final String emptyMessage;
  final CrmDealStatus status;
  final Future<void> Function(Deal deal, CrmDealStatus targetStatus) onDealDropped;
  final bool Function(int dealId) isDealUpdating;
  final Future<void> Function(Deal deal) onOpenChat;
  final Future<void> Function(Deal deal) onEditDeal;
  final Future<void> Function(Deal deal) onTransferDeal;
  final Future<void> Function() onLoadMore;
  final bool hasMore;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Deal>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) => onDealDropped(details.data, status),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        final alma = context.alma;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 350.w,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: isHovering ? AppTheme.brandMain2_100 : alma.surfaceVariant,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isHovering ? AppTheme.brandMain2_500 : alma.outline,
              width: isHovering ? 1.4 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppStyles.titleSmall.copyWith(
                          color: headerTextColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: headerTextColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Text(
                        counter.toString(),
                        style: AppStyles.labelSmall.copyWith(
                          color: headerTextColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: deals.isEmpty
                    ? _EmptyColumnState(message: emptyMessage)
                    : NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification.metrics.extentAfter <= 180 &&
                              hasMore &&
                              !isLoadingMore) {
                            onLoadMore();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          itemCount: deals.length + ((hasMore || isLoadingMore) ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= deals.length) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                child: Center(
                                  child: SizedBox(
                                    width: 18.w,
                                    height: 18.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final deal = deals[index];
                            return DealKanbanDraggableCard(
                              deal: deal,
                              isBusy: isDealUpdating(deal.id),
                              onOpenChat: onOpenChat,
                              onEditDeal: onEditDeal,
                              onTransferDeal: onTransferDeal,
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyColumnState extends StatelessWidget {
  const _EmptyColumnState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppStyles.bodySmall
              .copyWith(color: context.alma.onSurfaceHint),
        ),
      ),
    );
  }
}

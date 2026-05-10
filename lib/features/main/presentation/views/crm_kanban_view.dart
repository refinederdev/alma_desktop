import 'package:alma_desktop/core/theme/app_styles.dart';
import 'package:alma_desktop/core/theme/app_theme.dart';
import 'package:alma_desktop/core/widgets/agent_check_in_status_banner.dart';
import 'package:alma_desktop/features/main/presentation/controllers/crm_kanban_controller.dart';
import 'package:alma_desktop/features/main/presentation/widgets/kanban_column_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class CrmKanbanView extends GetView<CrmKanbanController> {
  const CrmKanbanView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CrmKanbanController>(
      builder: (c) {
        return Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AgentCheckInStatusBanner(),
              _CrmKanbanHeader(
                isRefreshing: c.isRefreshing,
                totalDeals: c.totalDeals,
                onRefresh: c.refreshBoard,
              ),
              SizedBox(height: 18.h),
              Expanded(
                child: c.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppTheme.baseWhite,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: AppTheme.gray50),
                        ),
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                KanbanColumnWidget(
                                  title: 'open_deals'.tr,
                                  counter: c.openDeals.length,
                                  deals: c.openDeals,
                                  status: CrmDealStatus.open,
                                  onDealDropped: c.moveDealToStatus,
                                  isDealUpdating: c.isDealUpdating,
                                  headerColor: AppTheme.warning50,
                                  headerTextColor: AppTheme.warning800,
                                  emptyMessage: 'no_open_deals_found'.tr,
                                  onOpenChat: c.openChatForDeal,
                                  onEditDeal: c.showEditDealDialog,
                                  onTransferDeal: c.showTransferDealDialog,
                                  onLoadMore: () =>
                                      c.loadMoreDealsByStatus(CrmDealStatus.open),
                                  hasMore: c.hasMoreDeals(CrmDealStatus.open),
                                  isLoadingMore: c.isLoadingMoreDeals(CrmDealStatus.open),
                                ),
                                SizedBox(width: 14.w),
                                KanbanColumnWidget(
                                  title: 'won_deals'.tr,
                                  counter: c.wonDeals.length,
                                  deals: c.wonDeals,
                                  status: CrmDealStatus.won,
                                  onDealDropped: c.moveDealToStatus,
                                  isDealUpdating: c.isDealUpdating,
                                  headerColor: AppTheme.success50,
                                  headerTextColor: AppTheme.success800,
                                  emptyMessage: 'no_won_deals_found'.tr,
                                  onOpenChat: c.openChatForDeal,
                                  onEditDeal: c.showEditDealDialog,
                                  onTransferDeal: c.showTransferDealDialog,
                                  onLoadMore: () =>
                                      c.loadMoreDealsByStatus(CrmDealStatus.won),
                                  hasMore: c.hasMoreDeals(CrmDealStatus.won),
                                  isLoadingMore: c.isLoadingMoreDeals(CrmDealStatus.won),
                                ),
                                SizedBox(width: 14.w),
                                KanbanColumnWidget(
                                  title: 'lost_deals'.tr,
                                  counter: c.lostDeals.length,
                                  deals: c.lostDeals,
                                  status: CrmDealStatus.lost,
                                  onDealDropped: c.moveDealToStatus,
                                  isDealUpdating: c.isDealUpdating,
                                  headerColor: AppTheme.error50,
                                  headerTextColor: AppTheme.error800,
                                  emptyMessage: 'no_lost_deals_found'.tr,
                                  onOpenChat: c.openChatForDeal,
                                  onEditDeal: c.showEditDealDialog,
                                  onTransferDeal: c.showTransferDealDialog,
                                  onLoadMore: () =>
                                      c.loadMoreDealsByStatus(CrmDealStatus.lost),
                                  hasMore: c.hasMoreDeals(CrmDealStatus.lost),
                                  isLoadingMore: c.isLoadingMoreDeals(CrmDealStatus.lost),
                                ),
                              ],
                            ),
                          ),
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

class _CrmKanbanHeader extends StatelessWidget {
  const _CrmKanbanHeader({
    required this.isRefreshing,
    required this.totalDeals,
    required this.onRefresh,
  });

  final bool isRefreshing;
  final int totalDeals;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppTheme.gray25,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.gray50),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'crm_kanban_title'.tr,
                  style: AppStyles.titleMedium.copyWith(
                    color: AppTheme.gray800,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'total_deals_count'.trParams({'count': totalDeals.toString()}),
                  style: AppStyles.bodySmall.copyWith(color: AppTheme.gray400),
                ),
                SizedBox(height: 2.h),
                Text(
                  'drag_drop_hint'.tr,
                  style: AppStyles.labelSmall.copyWith(color: AppTheme.gray300),
                ),
              ],
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

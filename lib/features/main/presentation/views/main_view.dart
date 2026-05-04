import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alma_desktop/core/theme/app_styles.dart';
import 'package:alma_desktop/core/theme/app_theme.dart';
import 'package:alma_desktop/core/widgets/alma_brand_logo.dart';
import 'package:alma_desktop/features/main/presentation/controllers/main_controller.dart';

class MainView extends GetView<MainController> {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray25,
      body: GetBuilder<MainController>(
        builder: (c) {
          return Row(
            children: [
              _MainSidebar(controller: c),
              Expanded(
                child: ColoredBox(
                  color: AppTheme.baseWhite,
                  child: c.views[c.selectedIndex],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MainSidebar extends StatelessWidget {
  const _MainSidebar({required this.controller});

  final MainController controller;

  @override
  Widget build(BuildContext context) {
    final items = <_SidebarItemData>[
      _SidebarItemData(
        label: 'dashboard'.tr,
        icon: Icons.dashboard_rounded,
        index: 0,
      ),
      _SidebarItemData(
        label: 'crm'.tr,
        icon: Icons.groups_rounded,
        index: 1,
      ),
      _SidebarItemData(
        label: 'chat'.tr,
        icon: Icons.chat_bubble_rounded,
        index: 2,
      ),
      _SidebarItemData(
        label: 'profile'.tr,
        icon: Icons.person_rounded,
        index: 3,
      ),
    ];

    return Container(
      width: 280.w,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.brandMain2_600, AppTheme.brandMain2],
        ),
        border: Border(
          right: BorderSide(
            color: AppTheme.baseWhite.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              color: AppTheme.baseWhite.withValues(alpha: 0.12),
            ),
            child: const AlmaBrandLogo(
              assetPath: 'assets/images/alma-full-logo.png',
              markSize: 80,
              maxWidth: 220,
              showWordmark: false,
              alignment: CrossAxisAlignment.center,
            ),
          ),
          SizedBox(height: 20.h),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => SizedBox(height: 8.h),
              itemBuilder: (context, i) {
                final item = items[i];
                final isSelected = controller.selectedIndex == item.index;
                return _SidebarTile(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => controller.changeView(item.index),
                );
              },
            ),
          ),
          _LogoutButton(onTap: controller.logout),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _SidebarItemData item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            color: isSelected
                ? AppTheme.baseWhite.withValues(alpha: 0.14)
                : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? AppTheme.brandMain300.withValues(alpha: 0.5)
                  : AppTheme.baseWhite.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: AppTheme.baseWhite,
                size: 22.sp,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  item.label,
                  style: AppStyles.titleSmall.copyWith(
                    color: AppTheme.baseWhite,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            color: AppTheme.error500.withValues(alpha: 0.2),
            border: Border.all(color: AppTheme.error500.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: AppTheme.baseWhite, size: 22.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'logout'.tr,
                  style: AppStyles.titleSmall.copyWith(
                    color: AppTheme.baseWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItemData {
  const _SidebarItemData({
    required this.label,
    required this.icon,
    required this.index,
  });

  final String label;
  final IconData icon;
  final int index;
}

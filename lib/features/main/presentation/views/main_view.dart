import 'package:alma_desktop/core/theme/alma_tokens.dart';
import 'package:alma_desktop/core/theme/app_styles.dart';
import 'package:alma_desktop/core/theme/app_theme.dart';
import 'package:alma_desktop/core/widgets/alma_brand_logo.dart';
import 'package:alma_desktop/features/global/presentation/controllers/global_controller.dart';
import 'package:alma_desktop/features/main/presentation/controllers/main_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// The persistent desktop workspace shell.
///
/// Navigation and account controls live here so every feature gets the same
/// predictable hierarchy without changing feature controllers or API flows.
class MainView extends GetView<MainController> {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MainController>(
      builder: (c) {
        const shortcutKeys = [
          LogicalKeyboardKey.digit1,
          LogicalKeyboardKey.digit2,
          LogicalKeyboardKey.digit3,
          LogicalKeyboardKey.digit4,
          LogicalKeyboardKey.digit5,
          LogicalKeyboardKey.digit6,
        ];
        return CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            for (var i = 0; i < c.views.length; i++)
              SingleActivator(shortcutKeys[i], meta: true): () =>
                  c.changeView(i),
            for (var i = 0; i < c.views.length; i++)
              SingleActivator(shortcutKeys[i], control: true): () =>
                  c.changeView(i),
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              backgroundColor: context.alma.scaffoldBg,
              body: SafeArea(
                child: Row(
                  children: [
                    _MainSidebar(controller: c),
                    Expanded(
                      child: Column(
                        children: [
                          _WorkspaceHeader(selectedIndex: c.selectedIndex),
                          Expanded(
                            child: Container(
                              margin: EdgeInsetsDirectional.only(
                                end: 16.w,
                                bottom: 16.h,
                              ),
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: context.alma.surface,
                                borderRadius: BorderRadius.circular(22.r),
                                border: Border.all(color: context.alma.outline),
                                boxShadow: context.alma.shadowXS,
                              ),
                              child: IndexedStack(
                                index: c.selectedIndex,
                                children: c.views,
                              ),
                            ),
                          ),
                        ],
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

class _MainSidebar extends StatelessWidget {
  const _MainSidebar({required this.controller});

  final MainController controller;

  @override
  Widget build(BuildContext context) {
    final s = context.alma;
    final items = <_SidebarItemData>[
      _SidebarItemData('dashboard'.tr, Icons.space_dashboard_rounded, 0),
      _SidebarItemData('crm'.tr, Icons.view_kanban_rounded, 1),
      _SidebarItemData('chat'.tr, Icons.forum_rounded, 2),
      _SidebarItemData('calls'.tr, Icons.call_rounded, 3),
      _SidebarItemData('profile'.tr, Icons.manage_accounts_rounded, 4),
      _SidebarItemData('updates'.tr, Icons.system_update_alt_rounded, 5),
    ];

    return Container(
      width: 242.w,
      margin: EdgeInsetsDirectional.fromSTEB(16.w, 16.h, 14.w, 16.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [s.sidebarGradientTop, s.sidebarGradientBottom],
        ),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: s.sidebarEdge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandMain2.withValues(alpha: 0.16),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 18.h),
            child: Row(
              children: [
                Container(
                  width: 42.w,
                  height: 42.w,
                  padding: EdgeInsets.all(7.w),
                  decoration: BoxDecoration(
                    color: s.sidebarLogoBackdrop,
                    borderRadius: BorderRadius.circular(13.r),
                    border: Border.all(color: s.sidebarEdge),
                  ),
                  child: const AlmaBrandLogo(
                    assetPath: 'assets/icon/icon.png',
                    markSize: 32,
                    maxWidth: 32,
                  ),
                ),
                SizedBox(width: 11.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ALMA',
                        style: AppStyles.titleMedium.copyWith(
                          color: s.sidebarForeground,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                      Text(
                        'CRM workspace',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.labelSmall.copyWith(
                          color: s.sidebarForeground.withValues(alpha: 0.64),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: s.sidebarEdge),
          SizedBox(height: 14.h),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, _) => SizedBox(height: 6.h),
              itemBuilder: (context, i) {
                final item = items[i];
                return _SidebarTile(
                  item: item,
                  isSelected: controller.selectedIndex == item.index,
                  onTap: () => controller.changeView(item.index),
                );
              },
            ),
          ),
          _AvailabilityCard(),
          SizedBox(height: 10.h),
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
    final s = context.alma;
    return Tooltip(
      message: '${item.label}  ⌘${item.index + 1}',
      waitDuration: const Duration(milliseconds: 600),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              color: isSelected ? s.sidebarTileSelected : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? s.sidebarTileBorderActive
                    : s.sidebarTileBorderIdle,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? s.sidebarForeground.withValues(alpha: 0.14)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    item.icon,
                    color: s.sidebarForeground,
                    size: 19.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    item.label,
                    style: AppStyles.titleSmall.copyWith(
                      color: s.sidebarForeground,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6.w,
                    height: 6.w,
                    decoration: BoxDecoration(
                      color: AppTheme.brandMain300,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.brandMain300.withValues(alpha: 0.55),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.alma;
    final user = GlobalController.to.user;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(11.w),
      decoration: BoxDecoration(
        color: s.sidebarForeground.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: s.sidebarEdge),
      ),
      child: Row(
        children: [
          Container(
            width: 9.w,
            height: 9.w,
            decoration: BoxDecoration(
              color: user?.isActive == false
                  ? AppTheme.warning400
                  : AppTheme.brandMain300,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 9.w),
          Expanded(
            child: Text(
              user?.isActive == false ? 'inactive'.tr : 'active'.tr,
              style: AppStyles.labelMedium.copyWith(
                color: s.sidebarForeground.withValues(alpha: 0.82),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({required this.selectedIndex});

  final int selectedIndex;

  static const _titleKeys = [
    'dashboard',
    'crm',
    'chat',
    'calls',
    'profile',
    'updates',
  ];

  static const _subtitleKeys = [
    'workspace_dashboard_subtitle',
    'workspace_crm_subtitle',
    'workspace_chat_subtitle',
    'workspace_calls_subtitle',
    'workspace_profile_subtitle',
    'workspace_updates_subtitle',
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.alma;
    final safeIndex = selectedIndex.clamp(0, _titleKeys.length - 1);
    return SizedBox(
      height: 92.h,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(4.w, 14.h, 20.w, 12.h),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titleKeys[safeIndex].tr,
                    style: AppStyles.headlineSmall.copyWith(
                      color: s.onSurfaceTitle,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.35,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _subtitleKeys[safeIndex].tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.bodySmall.copyWith(
                      color: s.onSurfaceTertiary,
                    ),
                  ),
                ],
              ),
            ),
            _HeaderAction(
              tooltip: 'change_language'.tr,
              icon: Icons.language_rounded,
              onTap: () {
                final global = GlobalController.to;
                global.changeLocale(
                  global.currentLocale.languageCode == 'ar'
                      ? const Locale('en', 'US')
                      : const Locale('ar', 'SA'),
                );
              },
            ),
            SizedBox(width: 8.w),
            GetBuilder<GlobalController>(
              builder: (global) => _HeaderAction(
                tooltip: 'appearance'.tr,
                icon: Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                onTap: () => global.setThemeMode(
                  Theme.of(context).brightness == Brightness.dark
                      ? ThemeMode.light
                      : ThemeMode.dark,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Container(width: 1, height: 32.h, color: s.divider),
            SizedBox(width: 12.w),
            _UserMenu(),
          ],
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: context.alma.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(color: context.alma.outline),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: onTap,
          child: SizedBox(
            width: 40.w,
            height: 40.w,
            child: Icon(
              icon,
              size: 19.sp,
              color: context.alma.onSurfaceSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _UserMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<GlobalController>(
      builder: (global) {
        final user = global.user;
        final initials = _initials(user?.fullName ?? 'A');
        return PopupMenuButton<String>(
          tooltip: 'account_settings'.tr,
          offset: Offset(0, 48.h),
          onSelected: (value) {
            if (value == 'profile') {
              Get.find<MainController>().changeView(4);
            } else if (value == 'logout') {
              Get.find<MainController>().logout();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'profile', child: Text('profile'.tr)),
            const PopupMenuDivider(),
            PopupMenuItem(value: 'logout', child: Text('logout'.tr)),
          ],
          child: Container(
            padding: EdgeInsetsDirectional.fromSTEB(5.w, 4.h, 10.w, 4.h),
            decoration: BoxDecoration(
              color: context.alma.surface,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: context.alma.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 17.r,
                  backgroundColor: AppTheme.brandMain2_600,
                  foregroundColor: Colors.white,
                  child: Text(
                    initials,
                    style: AppStyles.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: 9.w),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 130.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Alma',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.labelLarge.copyWith(
                          color: context.alma.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        user?.roles.firstOrNull ?? 'user'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.labelSmall.copyWith(
                          color: context.alma.onSurfaceTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 6.w),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18.sp,
                  color: context.alma.onSurfaceHint,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'A';
    return parts.take(2).map((e) => e.characters.first).join().toUpperCase();
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.alma;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(13.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: s.sidebarForeground.withValues(alpha: 0.8),
                size: 19.sp,
              ),
              SizedBox(width: 10.w),
              Text(
                'logout'.tr,
                style: AppStyles.labelLarge.copyWith(
                  color: s.sidebarForeground.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
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
  const _SidebarItemData(this.label, this.icon, this.index);

  final String label;
  final IconData icon;
  final int index;
}

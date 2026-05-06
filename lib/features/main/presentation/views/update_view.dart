import 'package:alma_desktop/core/theme/app_styles.dart';
import 'package:alma_desktop/core/theme/app_theme.dart';
import 'package:alma_desktop/features/main/presentation/controllers/update_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class UpdateView extends GetView<UpdateController> {
  const UpdateView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<UpdateController>(
      builder: (c) {
        final info = c.updateInfo;
        return SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 760.w),
            child: Container(
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                color: AppTheme.baseWhite,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppTheme.gray50),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'updates'.tr,
                    style: AppStyles.titleLarge.copyWith(
                      color: AppTheme.gray900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'updates_subtitle'.tr,
                    style: AppStyles.bodyMedium.copyWith(color: AppTheme.gray400),
                  ),
                  SizedBox(height: 16.h),
                  if (c.isChecking)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    _InfoRow(
                      label: 'current_version'.tr,
                      value: info?.currentVersion ?? c.currentVersion,
                    ),
                    SizedBox(height: 8.h),
                    _InfoRow(
                      label: 'latest_version'.tr,
                      value: info?.latestVersion ?? '--',
                    ),
                    SizedBox(height: 14.h),
                    if (c.errorMessage != null)
                      Text(
                        c.errorMessage!,
                        style: AppStyles.bodySmall.copyWith(color: AppTheme.error600),
                      )
                    else if (info == null)
                      Text(
                        'update_check_failed'.tr,
                        style: AppStyles.bodySmall.copyWith(color: AppTheme.error600),
                      )
                    else if (!info.hasUpdate)
                      Text(
                        'app_is_up_to_date'.tr,
                        style: AppStyles.bodyMedium.copyWith(color: AppTheme.success700),
                      )
                    else ...[
                      Text(
                        'new_update_available'.trParams({'version': info.latestVersion}),
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppTheme.brandMain2_600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      if (info.releaseNotes.trim().isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppTheme.gray25,
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(color: AppTheme.gray50),
                          ),
                          child: Text(
                            info.releaseNotes.trim(),
                            style: AppStyles.bodySmall.copyWith(color: AppTheme.gray700),
                          ),
                        ),
                    ],
                    if (c.isDownloading) ...[
                      SizedBox(height: 14.h),
                      LinearProgressIndicator(value: c.downloadProgress),
                      SizedBox(height: 6.h),
                      Text(
                        'downloading_update'.trParams({
                          'percent': (c.downloadProgress * 100).toStringAsFixed(0),
                        }),
                        style: AppStyles.bodySmall.copyWith(color: AppTheme.gray500),
                      ),
                    ],
                    if (c.isInstalling) ...[
                      SizedBox(height: 10.h),
                      Text(
                        'installing_update'.tr,
                        style: AppStyles.bodySmall.copyWith(color: AppTheme.gray500),
                      ),
                    ],
                    SizedBox(height: 16.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 10.h,
                      children: [
                        ElevatedButton.icon(
                          onPressed: c.isChecking || c.isDownloading || c.isInstalling
                              ? null
                              : c.checkForUpdates,
                          icon: Icon(Icons.refresh_rounded, size: 18.sp),
                          label: Text('check_for_updates'.tr),
                        ),
                        ElevatedButton.icon(
                          onPressed: c.isChecking ||
                                  c.isDownloading ||
                                  c.isInstalling ||
                                  info == null ||
                                  !info.hasUpdate
                              ? null
                              : c.updateNow,
                          icon: Icon(Icons.system_update_alt_rounded, size: 18.sp),
                          label: Text('update_now'.tr),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandMain2_600,
                            foregroundColor: AppTheme.baseWhite,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 180.w,
          child: Text(
            label,
            style: AppStyles.bodySmall.copyWith(color: AppTheme.gray400),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppStyles.bodyMedium.copyWith(
              color: AppTheme.gray800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

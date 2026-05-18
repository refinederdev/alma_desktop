import 'package:alma_desktop/core/theme/alma_tokens.dart';
import 'package:alma_desktop/core/theme/app_styles.dart';
import 'package:alma_desktop/core/theme/app_theme.dart';
import 'package:alma_desktop/core/widgets/app_button.dart';
import 'package:alma_desktop/features/calls/domain/entities/call_session.dart';
import 'package:alma_desktop/features/calls/presentation/controllers/call_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// حوار لإطلاق مكالمة صادرة (يختار الجلسة ويكتب الرقم).
class OutboundDialerDialog extends StatefulWidget {
  const OutboundDialerDialog({
    super.key,
    this.initialPhone,
    this.initialSessionId,
    this.contactName,
    this.dealId,
  });

  final String? initialPhone;
  final int? initialSessionId;
  final String? contactName;
  final int? dealId;

  @override
  State<OutboundDialerDialog> createState() => _OutboundDialerDialogState();
}

class _OutboundDialerDialogState extends State<OutboundDialerDialog> {
  late final TextEditingController _phoneController;
  int? _selectedSessionId;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
    final c = Get.find<CallController>();
    if (widget.initialSessionId != null &&
        c.sessions.any((s) => s.id == widget.initialSessionId)) {
      _selectedSessionId = widget.initialSessionId;
    } else if (c.sessions.isNotEmpty) {
      _selectedSessionId = c.sessions.first.id;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CallController>(
      builder: (c) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          backgroundColor: context.alma.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
            side: BorderSide(color: context.alma.outline),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 460.w),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 18.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: AppTheme.brandMain2_100,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.call_rounded,
                          color: AppTheme.brandMain2_600,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          'make_call'.tr,
                          style: AppStyles.titleMedium.copyWith(
                            color: context.alma.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close_rounded),
                        color: context.alma.onSurfaceTertiary,
                        tooltip: 'close'.tr,
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  if (widget.contactName != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Text(
                        widget.contactName!,
                        style: AppStyles.bodyMedium.copyWith(
                          color: context.alma.onSurfaceSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Text(
                    'session'.tr,
                    style: AppStyles.labelMedium.copyWith(
                      color: context.alma.onSurfaceSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  _SessionDropdown(
                    sessions: c.sessions,
                    selectedId: _selectedSessionId,
                    onChanged: (id) => setState(() => _selectedSessionId = id),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    'phone'.tr,
                    style: AppStyles.labelMedium.copyWith(
                      color: context.alma.onSurfaceSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: '971501234567',
                      prefixIcon: Icon(Icons.phone_outlined, size: 18.sp),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 12.h,
                      ),
                    ),
                    style: AppStyles.bodyMedium.copyWith(
                      color: context.alma.onSurface,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'phone_e164_hint'.tr,
                    style: AppStyles.labelSmall.copyWith(
                      color: context.alma.onSurfaceHint,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'call_now'.tr,
                      icon: Icons.call_rounded,
                      isLoading: c.isProcessing,
                      backgroundColor: AppTheme.success500,
                      borderColor: AppTheme.success500,
                      onPressed: () async {
                        if (_selectedSessionId == null) return;
                        final phone = _phoneController.text.trim();
                        if (phone.isEmpty) return;
                        Get.back();
                        await c.startOutboundCall(
                          sessionId: _selectedSessionId!,
                          toPhone: phone,
                          contactName: widget.contactName,
                          dealId: widget.dealId,
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
}

class _SessionDropdown extends StatelessWidget {
  const _SessionDropdown({
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
      decoration: BoxDecoration(
        color: context.alma.inputFill,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: context.alma.outline),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: selectedId,
          hint: Text(
            'select_session'.tr,
            style: AppStyles.bodySmall.copyWith(
              color: context.alma.onSurfaceHint,
            ),
          ),
          items: sessions
              .map(
                (s) => DropdownMenuItem<int>(
                  value: s.id,
                  child: Text(
                    s.sessionName ?? (s.phoneNumber ?? 'session ${s.id}'),
                    style: AppStyles.bodyMedium.copyWith(
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

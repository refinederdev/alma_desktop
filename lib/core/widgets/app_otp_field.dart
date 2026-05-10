import 'package:alma_desktop/core/theme/app_styles.dart';
import 'package:alma_desktop/core/theme/alma_tokens.dart';
import 'package:alma_desktop/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppOtpField extends StatefulWidget {
  final int length;
  final String? label;
  final Function(String)? onChanged;
  final Function(String)? onSubmit;

  const AppOtpField({
    super.key,
    this.length = 6,
    this.label,
    this.onChanged,
    this.onSubmit,
  });

  @override
  State<AppOtpField> createState() => _AppOtpFieldState();
}

class _AppOtpFieldState extends State<AppOtpField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _handleTextChanged(String value, int index) {
    if (value.isNotEmpty) {
      // Move to next field
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last field, submit
        _focusNodes[index].unfocus();
        _checkAndSubmit();
      }
    } else {
      // If field is cleared, move to previous field
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }

    // Call onChanged callback
    _checkAndSubmit();
  }

  void _checkAndSubmit() {
    String otp = _controllers.map((c) => c.text).join();
    widget.onChanged?.call(otp);
    if (otp.length == widget.length) {
      widget.onSubmit?.call(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final alma = context.alma;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppStyles.titleSmall.copyWith(color: alma.onSurface),
          ),
          SizedBox(height: 8.h),
        ],
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              widget.length,
              (index) => SizedBox(
                width: 48.w,
                height: 56.h,
                child: TextFormField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: AppStyles.titleLarge.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: alma.otpCaret,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) => _handleTextChanged(value, index),
                  onTap: () {
                    // Select all text when tapping on a field
                    _controllers[index].selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _controllers[index].text.length,
                    );
                  },
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: alma.inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(color: alma.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(color: alma.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(
                        color: AppTheme.brandMain2,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: AppTheme.error500),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 12.h,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

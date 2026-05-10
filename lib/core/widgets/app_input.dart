import 'package:alma_desktop/core/theme/app_styles.dart';
import 'package:alma_desktop/core/theme/alma_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppInputField extends StatelessWidget {
  final String? label;
  final String? hint;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool? isPassword;
  /// When [isPassword] is true, defaults to obscuring. Override for show/hide toggles.
  final bool? obscureText;
  final bool? isEnabled;
  final Function(String)? onChanged;
  final FormFieldValidator<String>? validator;
  final String? errorMessage;
  final Color? fillColor;
  final int? maxLines;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final void Function(String)? onFieldSubmitted;

  const AppInputField({
    super.key,
    this.label,
    this.hint,
    this.suffixIcon,
    this.prefixIcon,
    this.controller,
    this.keyboardType,
    this.isPassword,
    this.obscureText,
    this.isEnabled,
    this.onChanged,
    this.validator,
    this.errorMessage,
    this.fillColor,
    this.maxLines = 1,
    this.textInputAction,
    this.autofillHints,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final alma = context.alma;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppStyles.titleSmall.copyWith(color: alma.onSurface),
          ),
          SizedBox(height: 8.h),
        ],
        TextFormField(
          validator: validator,
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText ?? (isPassword == true),
          enabled: isEnabled ?? true,
          maxLines: maxLines,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          onFieldSubmitted: onFieldSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppStyles.bodyMedium.copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: alma.onSurfaceSecondary,
            ),
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
            errorText: errorMessage,
            fillColor: fillColor,
            filled: true,
          ),
        ),
      ],
    );
  }
}

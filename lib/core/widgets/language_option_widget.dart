import 'package:alma_desktop/core/theme/app_styles.dart';
import 'package:alma_desktop/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LanguageOptionWidget extends StatelessWidget {
  final String flagUrl;
  final String languageName;
  final bool isSelected;
  final VoidCallback onPressed;
  /// بطاقات أوضح لسطح المكتب (أيقونة أكبر وهوامش أرحب).
  final bool desktopStyle;

  const LanguageOptionWidget({
    super.key,
    required this.flagUrl,
    required this.languageName,
    required this.isSelected,
    required this.onPressed,
    this.desktopStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final flagSize = desktopStyle ? 44.0 : 32.0;
    final vPad = desktopStyle ? 20.h : 12.h;
    final hPad = desktopStyle ? 20.w : 16.w;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(desktopStyle ? 14.r : 16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.brandMain2_100
                : (desktopStyle ? AppTheme.gray25 : Colors.white),
            border: isSelected
                ? Border.all(color: AppTheme.brandMain2, width: 2)
                : desktopStyle
                    ? Border.all(color: AppTheme.gray100, width: 1)
                    : null,
            borderRadius: BorderRadius.circular(desktopStyle ? 14.r : 16.r),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.network(
                  flagUrl,
                  width: flagSize.w,
                  height: flagSize.w,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.flag_outlined,
                    size: flagSize.sp,
                    color: AppTheme.gray300,
                  ),
                ),
              ),
              SizedBox(width: desktopStyle ? 18.w : 16.w),
              Expanded(
                child: Text(
                  languageName,
                  style: (desktopStyle ? AppStyles.titleLarge : AppStyles.titleMedium)
                      .copyWith(
                    color: AppTheme.gray800,
                    fontWeight: desktopStyle ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              _CustomRadio(isSelected: isSelected, desktopStyle: desktopStyle),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomRadio extends StatelessWidget {
  const _CustomRadio({required this.isSelected, this.desktopStyle = false});

  final bool isSelected;
  final bool desktopStyle;

  @override
  Widget build(BuildContext context) {
    final outer = desktopStyle ? 22.0 : 20.0;
    final inner = desktopStyle ? 12.0 : 12.0;
    return Container(
      width: outer.w,
      height: outer.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppTheme.brandMain2 : AppTheme.gray300,
          width: 2,
        ),
        color: Colors.transparent,
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: inner.w,
                height: inner.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.brandMain2,
                ),
              ),
            )
          : null,
    );
  }
}

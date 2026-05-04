import 'dart:math' as math;
import 'package:alma_desktop/core/theme/app_styles.dart';
import 'package:alma_desktop/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final IconData? icon;
  final TextStyle? textStyle;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.width,
    this.height,
    this.padding,
    this.icon,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedHeight = height ?? 48.h;
    final btnContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon!, color: textColor ?? AppTheme.baseWhite, size: 20.sp),
          SizedBox(width: 8.w),
        ],
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style:
                textStyle ??
                AppStyles.titleMedium.copyWith(
                  color: textColor ?? AppTheme.baseWhite,
                ),
          ),
        ),
      ],
    );

    return SizedBox(
      width: width,
      height: resolvedHeight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: AppTheme.brandMain2_500,
          disabledForegroundColor: (textColor ?? AppTheme.baseWhite).withValues(
            alpha: 0.7,
          ),
          backgroundColor: backgroundColor ?? AppTheme.brandMain2,
          foregroundColor: textColor ?? AppTheme.baseWhite,
          side: BorderSide(
            color: isDisabled || isLoading
                ? AppTheme.brandMain2_500
                : borderColor ?? AppTheme.brandMain2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          padding:
              padding ?? EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
          elevation: 0,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: Size(132.w, resolvedHeight),
        ),
        onPressed: (isDisabled || isLoading) ? null : onPressed,
        child: SizedBox(
          height: 20.h,
          child: Center(
            child: isLoading
                ? SizedBox(
                    height: 20.h,
                    width: 20.h,
                    child: _EnhancedCircularProgressIndicator(
                      color: textColor ?? AppTheme.baseWhite,
                      size: 20.h,
                    ),
                  )
                : btnContent,
          ),
        ),
      ),
    );
  }
}

/// مؤشر تقدم بسيط على شكل قوس أبيض سميك
class _EnhancedCircularProgressIndicator extends StatefulWidget {
  final Color color;
  final double size;

  const _EnhancedCircularProgressIndicator({
    required this.color,
    required this.size,
  });

  @override
  State<_EnhancedCircularProgressIndicator> createState() =>
      _EnhancedCircularProgressIndicatorState();
}

class _EnhancedCircularProgressIndicatorState
    extends State<_EnhancedCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _ArcProgressPainter(color: widget.color),
          ),
        );
      },
    );
  }
}

class _ArcProgressPainter extends CustomPainter {
  final Color color;

  _ArcProgressPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // رسم القوس الأبيض السميك
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // رسم قوس يشبه حرف U مقلوب (حوالي 180 درجة)
    final startAngle = -math.pi / 2; // يبدأ من الأعلى
    final sweepAngle = math.pi; // 180 درجة

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

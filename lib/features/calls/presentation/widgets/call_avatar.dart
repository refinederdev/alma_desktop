import 'package:alma_desktop/core/theme/app_styles.dart';
import 'package:alma_desktop/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// أفاتار دائري لرقم/اسم العميل أثناء المكالمة (مع نبض اختياري).
class CallAvatar extends StatefulWidget {
  const CallAvatar({
    super.key,
    required this.label,
    this.size = 96,
    this.pulse = false,
    this.background,
    this.foreground,
  });

  final String label;
  final double size;
  final bool pulse;
  final Color? background;
  final Color? foreground;

  @override
  State<CallAvatar> createState() => _CallAvatarState();
}

class _CallAvatarState extends State<CallAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.pulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant CallAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.pulse && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _initials(String label) {
    final clean = label.trim();
    if (clean.isEmpty) return '#';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return (parts[0].characters.first + parts[1].characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.background ?? AppTheme.brandMain2_100;
    final fg = widget.foreground ?? AppTheme.brandMain2_600;
    final size = widget.size.w;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final scale = widget.pulse
            ? 1 + (_controller.value * 0.18)
            : 1.0;
        return SizedBox(
          width: size * 1.35,
          height: size * 1.35,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.pulse)
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bg.withValues(alpha: 0.55 - _controller.value * 0.4),
                    ),
                  ),
                ),
              Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [bg, bg.withValues(alpha: 0.85)],
                  ),
                  border: Border.all(
                    color: fg.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Text(
                  _initials(widget.label),
                  style: AppStyles.headlineSmall.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
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

import 'package:alma_desktop/core/theme/app_theme.dart';
import 'package:alma_desktop/features/main/presentation/controllers/splash_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  static const String _logoAsset = 'assets/images/alma-full-logo-blue.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.brandMain25,
              AppTheme.baseWhite,
              AppTheme.brandMain2_100,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 16 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 48.w),
                  child: Image.asset(
                    _logoAsset,
                    fit: BoxFit.contain,
                    width: 0.42.sw,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: 28.w,
                height: 28.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.brandMain2.withValues(alpha: 0.85),
                ),
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}

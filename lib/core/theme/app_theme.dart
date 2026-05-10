import 'dart:ui';

import 'package:alma_desktop/core/theme/alma_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_styles.dart';

/// لوحة الألوان الثابتة + بناة [ThemeData] للوضع الفاتح والداكن.
abstract final class AppTheme {
  AppTheme._();

  /* ----------------------------------------------------
   * BRAND COLORS (From Colors Guide)
   * -------------------------------------------------- */
  /// Brand Main
  static const Color brandMain = Color(0xFF00A48F);
  static const Color brandMain25 = Color(0xFFEEFFFA);
  static const Color brandMain50 = Color(0xFFC6FFF2);
  static const Color brandMain100 = Color(0xFF8EFFE6);
  static const Color brandMain200 = Color(0xFF48C8FF);
  static const Color brandMain300 = Color(0xFF19E8C5);
  static const Color brandMain400 = Color(0xFF00D2B2);
  static const Color brandMain600 = Color(0xFF028374);
  static const Color brandMain700 = Color(0xFF08675D);
  static const Color brandMain800 = Color(0xFF0C554D);

  /// Brand Main 2
  static const Color brandMain2 = Color(0xFF006CEA);
  static const Color brandMain2_100 = Color(0xFFD6F1FF);
  static const Color brandMain2_200 = Color(0xFFB5E9FF);
  static const Color brandMain2_300 = Color(0xFF83DDFF);
  static const Color brandMain2_400 = Color(0xFF48C8FF);
  static const Color brandMain2_500 = Color(0xFF1EA8FF);
  static const Color brandMain2_600 = Color(0xFF068AFF);

  /* ----------------------------------------------------
   * GRAY SCALE
   * -------------------------------------------------- */

  static const Color gray25 = Color(0xFFFCFCFD);
  static const Color gray50 = Color(0xFFEBECEE);
  static const Color gray100 = Color(0xFFF9FAFB);
  static const Color gray200 = Color(0xFFA2A7B0);
  static const Color gray300 = Color(0xFF777F8C);
  static const Color gray400 = Color(0xFF5D6676);
  static const Color gray500 = Color(0xFF344054);
  static const Color gray600 = Color(0xFF2F3A4C);
  static const Color gray700 = Color(0xFF252D3C);
  static const Color gray800 = Color(0xFF1D232E);
  static const Color gray900 = Color(0xFF161B23);

  /* ----------------------------------------------------
   * SUCCESS
   * -------------------------------------------------- */

  static const Color success25 = Color(0xFFF6FEF9);
  static const Color success50 = Color(0xFFE8F7F1);
  static const Color success100 = Color(0xFFB8E7D2);
  static const Color success200 = Color(0xFF95DCBC);
  static const Color success300 = Color(0xFF65CC9E);
  static const Color success400 = Color(0xFF47C28B);
  static const Color success500 = Color(0xFF19B36E);
  static const Color success600 = Color(0xFF17A364);
  static const Color success700 = Color(0xFF127F4E);
  static const Color success800 = Color(0xFF0E623D);
  static const Color success900 = Color(0xFF0B4B2E);

  /* ----------------------------------------------------
   * ERROR
   * -------------------------------------------------- */

  static const Color error25 = Color(0xFFFFFBFA);
  static const Color error50 = Color(0xFFFFEEEE);
  static const Color error100 = Color(0xFFFDCACA);
  static const Color error200 = Color(0xFFFCB1B1);
  static const Color error300 = Color(0xFFFB8D8D);
  static const Color error400 = Color(0xFFFA7777);
  static const Color error500 = Color(0xFFF95555);
  static const Color error600 = Color(0xFFE34D4D);
  static const Color error700 = Color(0xFFB13C3C);
  static const Color error800 = Color(0xFF892F2F);
  static const Color error900 = Color(0xFF692424);

  /* ----------------------------------------------------
   * WARNING
   * -------------------------------------------------- */

  static const Color warning25 = Color(0xFFFFF7EC);
  static const Color warning50 = Color(0xFFFFF7EC);
  static const Color warning100 = Color(0xFFFFE6C4);
  static const Color warning200 = Color(0xFFFFD9A8);
  static const Color warning300 = Color(0xFFFFC880);
  static const Color warning400 = Color(0xFFFFBD68);
  static const Color warning500 = Color(0xFFFFAD42);
  static const Color warning600 = Color(0xFFE89D3C);
  static const Color warning700 = Color(0xFFB57B2F);
  static const Color warning800 = Color(0xFF8C5F24);
  static const Color warning900 = Color(0xFF6B491C);

  /* ----------------------------------------------------
   * BASE
   * -------------------------------------------------- */

  static const Color baseWhite = Color(0xFFFFFFFF);
  static const Color baseBlack = Color(0xFF1D232E);

  /* ----------------------------------------------------
   * GRADIENTS
   * -------------------------------------------------- */

  static LinearGradient primaryGradient = const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [brandMain, brandMain2],
  );

  /* ----------------------------------------------------
   * SHADOWS (ثابتة — يُفضّل [AlmaTokens.shadowXS] حسب السمة)
   * -------------------------------------------------- */

  static List<BoxShadow> shadowXS = [
    BoxShadow(
      color: baseBlack.withValues(alpha: 0.08),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowSM = [
    BoxShadow(
      color: baseBlack.withValues(alpha: 0.12),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  /* ----------------------------------------------------
   * BLUR
   * -------------------------------------------------- */

  static ImageFilter bgBlurXS = ImageFilter.blur(sigmaX: 4, sigmaY: 4);

  /* ----------------------------------------------------
   * THEME DATA
   * -------------------------------------------------- */

  static ThemeData get lightTheme => _buildTheme(brightness: Brightness.light);

  static ThemeData get darkTheme => _buildTheme(brightness: Brightness.dark);

  /// للتوافق مع الكود القديم
  static ThemeData get appTheme => lightTheme;

  static ThemeData _buildTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    final tokens = isDark ? AlmaTokens.dark : AlmaTokens.light;

    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: brandMain2_400,
            secondary: brandMain300,
            error: error400,
            surface: tokens.surface,
            onPrimary: baseWhite,
            onSecondary: gray900,
            onError: baseWhite,
            onSurface: tokens.onSurface,
          )
        : ColorScheme.light(
            primary: brandMain2,
            secondary: brandMain,
            error: error500,
            surface: tokens.surface,
            onPrimary: baseWhite,
            onSecondary: baseWhite,
            onError: baseWhite,
            onSurface: tokens.onSurface,
          );

    final borderColor = tokens.outlineVariant;
    final fillColor = tokens.inputFill.withValues(alpha: isDark ? 0.85 : 0.5);

    return ThemeData(
      useMaterial3: false,
      brightness: brightness,
      scaffoldBackgroundColor: tokens.scaffoldBg,
      fontFamily: 'IBMPlexSansArabic',
      colorScheme: colorScheme,
      extensions: <ThemeExtension<dynamic>>[tokens],
      textTheme: TextTheme(
        displayLarge: AppStyles.displayLarge.copyWith(color: tokens.onSurface),
        displayMedium:
            AppStyles.displayMedium.copyWith(color: tokens.onSurface),
        displaySmall: AppStyles.displaySmall.copyWith(color: tokens.onSurface),
        headlineLarge:
            AppStyles.headlineLarge.copyWith(color: tokens.onSurface),
        headlineMedium:
            AppStyles.headlineMedium.copyWith(color: tokens.onSurface),
        headlineSmall:
            AppStyles.headlineSmall.copyWith(color: tokens.onSurface),
        titleLarge: AppStyles.titleLarge.copyWith(color: tokens.onSurface),
        titleMedium: AppStyles.titleMedium.copyWith(color: tokens.onSurface),
        titleSmall: AppStyles.titleSmall.copyWith(color: tokens.onSurface),
        bodyLarge: AppStyles.bodyLarge.copyWith(color: tokens.onSurface),
        bodyMedium: AppStyles.bodyMedium.copyWith(color: tokens.onSurface),
        bodySmall: AppStyles.bodySmall.copyWith(color: tokens.onSurface),
        labelLarge: AppStyles.labelLarge.copyWith(color: tokens.onSurface),
        labelMedium: AppStyles.labelMedium.copyWith(color: tokens.onSurface),
        labelSmall: AppStyles.labelSmall.copyWith(color: tokens.onSurface),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppStyles.titleMedium.copyWith(
          color: tokens.onSurface,
          fontFamily: 'IBMPlexSansArabic',
        ),
        foregroundColor: tokens.onSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandMain2,
          foregroundColor: baseWhite,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.onSurface,
          side: BorderSide(color: tokens.outline),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: brandMain2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: error500),
        ),
        iconColor: tokens.onSurfaceHint,
        hintStyle:
            AppStyles.labelMedium.copyWith(color: tokens.onSurfaceSecondary),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      ),
      dividerTheme: DividerThemeData(color: tokens.divider, thickness: 1),
      dialogTheme: DialogThemeData(backgroundColor: tokens.surface),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          tokens.onSurfaceHint.withValues(alpha: 0.45),
        ),
        radius: Radius.circular(8.r),
      ),
    );
  }
}

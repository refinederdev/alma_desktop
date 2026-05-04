import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'app_styles.dart';

class AppTheme extends GetxController {
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
   * SHADOWS
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

  static ThemeData appTheme = ThemeData(
    useMaterial3: false,
    scaffoldBackgroundColor: baseWhite,
    fontFamily: "IBMPlexSansArabic",
    colorScheme: ColorScheme.light(
      primary: brandMain2,
      secondary: brandMain,
      error: error500,
      surface: baseWhite,
      onPrimary: baseWhite,
      onSecondary: baseWhite,
      onError: baseWhite,
      onSurface: gray800,
    ),
    textTheme: const TextTheme().apply(
      fontSizeFactor: 1.sp,
      bodyColor: gray800,
      displayColor: gray800,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppStyles.titleMedium.copyWith(
        color: gray800,
        fontFamily: "IBMPlexSansArabic",
      ),
      foregroundColor: gray800,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: brandMain2,
        foregroundColor: baseWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: gray50.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: const BorderSide(color: gray100),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: const BorderSide(color: gray100),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: const BorderSide(color: brandMain2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: const BorderSide(color: error500),
      ),
      iconColor: gray300,
      hintStyle: AppStyles.labelMedium.copyWith(color: gray500),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
    ),
  );
}

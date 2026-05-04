import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppStyles {
  AppStyles();

  /* ----------------------------------------------------
   * FONT FAMILY
   * -------------------------------------------------- */

  // static const String _fontFamily = 'Inter';
  // If Arabic is required, replace with:
  static const String _fontFamily = 'IBMPlexSansArabic';

  /* ----------------------------------------------------
   * DISPLAY
   * -------------------------------------------------- */

  /// Display Large — Inter 57 / 64  | -0.25
  static TextStyle displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 57.sp,
    height: 64 / 57,
    letterSpacing: -0.25,
    fontWeight: FontWeight.w400,
  );

  /// Display Medium — Inter 45 / 52
  static TextStyle displayMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 45.sp,
    height: 52 / 45,
    fontWeight: FontWeight.w400,
  );

  /// Display Small — Inter 36 / 44
  static TextStyle displaySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 36.sp,
    height: 44 / 36,
    fontWeight: FontWeight.w400,
  );

  /* ----------------------------------------------------
   * HEADLINE
   * -------------------------------------------------- */

  /// Headline Large — Inter 32 / 40
  static TextStyle headlineLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32.sp,
    height: 40 / 32,
    fontWeight: FontWeight.w400,
  );

  /// Headline Medium — Inter 28 / 36
  static TextStyle headlineMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28.sp,
    height: 36 / 28,
    fontWeight: FontWeight.w400,
  );

  /// Headline Small — Inter 24 / 32
  static TextStyle headlineSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24.sp,
    height: 32 / 24,
    fontWeight: FontWeight.w400,
  );

  /* ----------------------------------------------------
   * TITLE
   * -------------------------------------------------- */

  /// Title Large — Inter Regular 22 / 28
  static TextStyle titleLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22.sp,
    height: 28 / 22,
    fontWeight: FontWeight.w400,
  );

  /// Title Medium — Inter Medium 16 / 24 | +0.15
  static TextStyle titleMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16.sp,
    height: 24 / 16,
    letterSpacing: 0.15,
    fontWeight: FontWeight.w500,
  );

  /// Title Small — Inter Medium 14 / 20 | +0.1
  static TextStyle titleSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14.sp,
    height: 20 / 14,
    letterSpacing: 0.1,
    fontWeight: FontWeight.w500,
  );

  /* ----------------------------------------------------
   * LABEL
   * -------------------------------------------------- */

  /// Label Large — Inter Medium 14 / 20 | +0.1
  static TextStyle labelLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14.sp,
    height: 20 / 14,
    letterSpacing: 0.1,
    fontWeight: FontWeight.w500,
  );

  /// Label Medium — Inter Medium 12 / 16 | -0.5
  static TextStyle labelMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12.sp,
    height: 16 / 12,
    letterSpacing: -0.5,
    fontWeight: FontWeight.w500,
  );

  /// Label Small — Inter Medium 11 / 16 | -0.15
  static TextStyle labelSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11.sp,
    height: 16 / 11,
    letterSpacing: -0.15,
    fontWeight: FontWeight.w500,
  );

  /* ----------------------------------------------------
   * BODY
   * -------------------------------------------------- */

  /// Body Large — Inter 16 / 24 | +0.5
  static TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16.sp,
    height: 24 / 16,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w400,
  );

  /// Body Medium — Inter 14 / 20 | +0.25
  static TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14.sp,
    height: 20 / 14,
    letterSpacing: 0.25,
    fontWeight: FontWeight.w400,
  );

  /// Body Small — Inter 12 / 16 | -0.2
  static TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12.sp,
    height: 16 / 12,
    letterSpacing: -0.2,
    fontWeight: FontWeight.w400,
  );

  static Color randomLightColor() {
    final random = Random();
    int r = 200 + random.nextInt(56); // 200-255 for light color
    int g = 200 + random.nextInt(56);
    int b = 200 + random.nextInt(56);
    return Color.fromARGB(255, r, g, b);
  }
}

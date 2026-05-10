import 'package:flutter/material.dart';

/// ألوان دلالية تتبع سمة التطبيق (فاتح / داكن). تُربَط عبر [ThemeExtension].
@immutable
class AlmaTokens extends ThemeExtension<AlmaTokens> {
  const AlmaTokens({
    required this.scaffoldBg,
    required this.surface,
    required this.surfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.outlineStrong,
    required this.onSurface,
    required this.onSurfaceTitle,
    required this.onSurfaceSecondary,
    required this.onSurfaceTertiary,
    required this.onSurfaceHint,
    required this.divider,
    required this.inputFill,
    required this.modalBarrier,
    required this.shadowBase,
    required this.bottomSheetBg,
    required this.kanbanOpenHeaderBg,
    required this.kanbanOpenHeaderFg,
    required this.kanbanWonHeaderBg,
    required this.kanbanWonHeaderFg,
    required this.kanbanLostHeaderBg,
    required this.kanbanLostHeaderFg,
    required this.selectionSoftBg,
    required this.splashA,
    required this.splashB,
    required this.splashC,
    required this.warningBannerBg,
    required this.warningBannerBorder,
    required this.warningBannerTitle,
    required this.warningBannerBody,
    required this.chatBubbleOtherBg,
    required this.chatBubbleOtherBorder,
    required this.statusOpenBg,
    required this.statusOpenFg,
    required this.statusWonBg,
    required this.statusWonFg,
    required this.statusLostBg,
    required this.statusLostFg,
    required this.otpCaret,
    required this.mediaPlaceholderBg,
    required this.subtleAccentBg,
    required this.subtleAccentBorder,
    required this.sidebarGradientTop,
    required this.sidebarGradientBottom,
    required this.sidebarEdge,
    required this.sidebarLogoBackdrop,
    required this.sidebarForeground,
    required this.sidebarTileSelected,
    required this.sidebarTileBorderActive,
    required this.sidebarTileBorderIdle,
  });

  final Color scaffoldBg;
  final Color surface;
  final Color surfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color outlineStrong;
  final Color onSurface;
  final Color onSurfaceTitle;
  final Color onSurfaceSecondary;
  final Color onSurfaceTertiary;
  final Color onSurfaceHint;
  final Color divider;
  final Color inputFill;
  final Color modalBarrier;
  final Color shadowBase;
  final Color bottomSheetBg;
  final Color kanbanOpenHeaderBg;
  final Color kanbanOpenHeaderFg;
  final Color kanbanWonHeaderBg;
  final Color kanbanWonHeaderFg;
  final Color kanbanLostHeaderBg;
  final Color kanbanLostHeaderFg;
  final Color selectionSoftBg;
  final Color splashA;
  final Color splashB;
  final Color splashC;
  final Color warningBannerBg;
  final Color warningBannerBorder;
  final Color warningBannerTitle;
  final Color warningBannerBody;
  final Color chatBubbleOtherBg;
  final Color chatBubbleOtherBorder;
  final Color statusOpenBg;
  final Color statusOpenFg;
  final Color statusWonBg;
  final Color statusWonFg;
  final Color statusLostBg;
  final Color statusLostFg;
  final Color otpCaret;
  final Color mediaPlaceholderBg;
  final Color subtleAccentBg;
  final Color subtleAccentBorder;

  /// الشريط الجانبي الرئيسي (يتبع الفاتح / الداكن).
  final Color sidebarGradientTop;
  final Color sidebarGradientBottom;
  final Color sidebarEdge;
  final Color sidebarLogoBackdrop;
  final Color sidebarForeground;
  final Color sidebarTileSelected;
  final Color sidebarTileBorderActive;
  final Color sidebarTileBorderIdle;

  static const AlmaTokens fallback = light;

  static const AlmaTokens light = AlmaTokens(
    scaffoldBg: Color(0xFFFCFCFD),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFFCFCFD),
    outline: Color(0xFFEBECEE),
    outlineVariant: Color(0xFFF9FAFB),
    outlineStrong: Color(0xFFA2A7B0),
    onSurface: Color(0xFF1D232E),
    onSurfaceTitle: Color(0xFF161B23),
    onSurfaceSecondary: Color(0xFF344054),
    onSurfaceTertiary: Color(0xFF5D6676),
    onSurfaceHint: Color(0xFF777F8C),
    divider: Color(0xFFEBECEE),
    inputFill: Color(0xFFFCFCFD),
    modalBarrier: Color(0x73000000),
    shadowBase: Color(0xFF1D232E),
    bottomSheetBg: Color(0xFFFFFFFF),
    kanbanOpenHeaderBg: Color(0xFFFFF7EC),
    kanbanOpenHeaderFg: Color(0xFF8C5F24),
    kanbanWonHeaderBg: Color(0xFFE8F7F1),
    kanbanWonHeaderFg: Color(0xFF0E623D),
    kanbanLostHeaderBg: Color(0xFFFFEEEE),
    kanbanLostHeaderFg: Color(0xFF892F2F),
    selectionSoftBg: Color(0xFFD6F1FF),
    splashA: Color(0xFFEEFFFA),
    splashB: Color(0xFFFFFFFF),
    splashC: Color(0xFFD6F1FF),
    warningBannerBg: Color(0xFFFFF7EC),
    warningBannerBorder: Color(0xFFFFD9A8),
    warningBannerTitle: Color(0xFF6B491C),
    warningBannerBody: Color(0xFF8C5F24),
    chatBubbleOtherBg: Color(0xFFFCFCFD),
    chatBubbleOtherBorder: Color(0xFFEBECEE),
    statusOpenBg: Color(0xFFFFF7EC),
    statusOpenFg: Color(0xFF8C5F24),
    statusWonBg: Color(0xFFE8F7F1),
    statusWonFg: Color(0xFF0E623D),
    statusLostBg: Color(0xFFFFEEEE),
    statusLostFg: Color(0xFF892F2F),
    otpCaret: Color(0xFF1D232E),
    mediaPlaceholderBg: Color(0xFFEBECEE),
    subtleAccentBg: Color(0x140068EA),
    subtleAccentBorder: Color(0x140068EA),
    sidebarGradientTop: Color(0xFF068AFF),
    sidebarGradientBottom: Color(0xFF006CEA),
    sidebarEdge: Color(0x1FFFFFFF),
    sidebarLogoBackdrop: Color(0x1FFFFFFF),
    sidebarForeground: Color(0xFFFFFFFF),
    sidebarTileSelected: Color(0x24FFFFFF),
    sidebarTileBorderActive: Color(0x8019E8C5),
    sidebarTileBorderIdle: Color(0x14FFFFFF),
  );

  static const AlmaTokens dark = AlmaTokens(
    scaffoldBg: Color(0xFF0D1117),
    surface: Color(0xFF161B22),
    surfaceVariant: Color(0xFF21262D),
    outline: Color(0xFF30363D),
    outlineVariant: Color(0xFF21262D),
    outlineStrong: Color(0xFF484F58),
    onSurface: Color(0xFFE6EDF3),
    onSurfaceTitle: Color(0xFFF0F6FC),
    onSurfaceSecondary: Color(0xFF8B949E),
    onSurfaceTertiary: Color(0xFF6E7681),
    onSurfaceHint: Color(0xFF484F58),
    divider: Color(0xFF30363D),
    inputFill: Color(0xFF0D1117),
    modalBarrier: Color(0x99000000),
    shadowBase: Color(0xFF000000),
    bottomSheetBg: Color(0xFF161B22),
    kanbanOpenHeaderBg: Color(0xFF3D2E14),
    kanbanOpenHeaderFg: Color(0xFFFFC880),
    kanbanWonHeaderBg: Color(0xFF0F2918),
    kanbanWonHeaderFg: Color(0xFF65CC9E),
    kanbanLostHeaderBg: Color(0xFF3D1518),
    kanbanLostHeaderFg: Color(0xFFFB8D8D),
    selectionSoftBg: Color(0xFF0D2840),
    splashA: Color(0xFF062923),
    splashB: Color(0xFF0A1620),
    splashC: Color(0xFF0D2135),
    warningBannerBg: Color(0xFF2D2410),
    warningBannerBorder: Color(0xFF5C4A1C),
    warningBannerTitle: Color(0xFFFFD9A8),
    warningBannerBody: Color(0xFFFFC880),
    chatBubbleOtherBg: Color(0xFF21262D),
    chatBubbleOtherBorder: Color(0xFF30363D),
    statusOpenBg: Color(0xFF3D2E14),
    statusOpenFg: Color(0xFFFFC880),
    statusWonBg: Color(0xFF0F2918),
    statusWonFg: Color(0xFF65CC9E),
    statusLostBg: Color(0xFF3D1518),
    statusLostFg: Color(0xFFFB8D8D),
    otpCaret: Color(0xFFF0F6FC),
    mediaPlaceholderBg: Color(0xFF30363D),
    subtleAccentBg: Color(0x331EA8FF),
    subtleAccentBorder: Color(0x331EA8FF),
    sidebarGradientTop: Color(0xFF1A2332),
    sidebarGradientBottom: Color(0xFF0D1117),
    sidebarEdge: Color(0xFF30363D),
    sidebarLogoBackdrop: Color(0x14FFFFFF),
    sidebarForeground: Color(0xFFE6EDF3),
    sidebarTileSelected: Color(0x1FFFFFFF),
    sidebarTileBorderActive: Color(0x6648C8FF),
    sidebarTileBorderIdle: Color(0x3330363D),
  );

  List<BoxShadow> get shadowXS => [
        BoxShadow(
          color: shadowBase.withValues(alpha: 0.08),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  List<BoxShadow> get shadowSM => [
        BoxShadow(
          color: shadowBase.withValues(alpha: 0.14),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  @override
  AlmaTokens copyWith({
    Color? scaffoldBg,
    Color? surface,
    Color? surfaceVariant,
    Color? outline,
    Color? outlineVariant,
    Color? outlineStrong,
    Color? onSurface,
    Color? onSurfaceTitle,
    Color? onSurfaceSecondary,
    Color? onSurfaceTertiary,
    Color? onSurfaceHint,
    Color? divider,
    Color? inputFill,
    Color? modalBarrier,
    Color? shadowBase,
    Color? bottomSheetBg,
    Color? kanbanOpenHeaderBg,
    Color? kanbanOpenHeaderFg,
    Color? kanbanWonHeaderBg,
    Color? kanbanWonHeaderFg,
    Color? kanbanLostHeaderBg,
    Color? kanbanLostHeaderFg,
    Color? selectionSoftBg,
    Color? splashA,
    Color? splashB,
    Color? splashC,
    Color? warningBannerBg,
    Color? warningBannerBorder,
    Color? warningBannerTitle,
    Color? warningBannerBody,
    Color? chatBubbleOtherBg,
    Color? chatBubbleOtherBorder,
    Color? statusOpenBg,
    Color? statusOpenFg,
    Color? statusWonBg,
    Color? statusWonFg,
    Color? statusLostBg,
    Color? statusLostFg,
    Color? otpCaret,
    Color? mediaPlaceholderBg,
    Color? subtleAccentBg,
    Color? subtleAccentBorder,
    Color? sidebarGradientTop,
    Color? sidebarGradientBottom,
    Color? sidebarEdge,
    Color? sidebarLogoBackdrop,
    Color? sidebarForeground,
    Color? sidebarTileSelected,
    Color? sidebarTileBorderActive,
    Color? sidebarTileBorderIdle,
  }) {
    return AlmaTokens(
      scaffoldBg: scaffoldBg ?? this.scaffoldBg,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      outline: outline ?? this.outline,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      outlineStrong: outlineStrong ?? this.outlineStrong,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceTitle: onSurfaceTitle ?? this.onSurfaceTitle,
      onSurfaceSecondary: onSurfaceSecondary ?? this.onSurfaceSecondary,
      onSurfaceTertiary: onSurfaceTertiary ?? this.onSurfaceTertiary,
      onSurfaceHint: onSurfaceHint ?? this.onSurfaceHint,
      divider: divider ?? this.divider,
      inputFill: inputFill ?? this.inputFill,
      modalBarrier: modalBarrier ?? this.modalBarrier,
      shadowBase: shadowBase ?? this.shadowBase,
      bottomSheetBg: bottomSheetBg ?? this.bottomSheetBg,
      kanbanOpenHeaderBg: kanbanOpenHeaderBg ?? this.kanbanOpenHeaderBg,
      kanbanOpenHeaderFg: kanbanOpenHeaderFg ?? this.kanbanOpenHeaderFg,
      kanbanWonHeaderBg: kanbanWonHeaderBg ?? this.kanbanWonHeaderBg,
      kanbanWonHeaderFg: kanbanWonHeaderFg ?? this.kanbanWonHeaderFg,
      kanbanLostHeaderBg: kanbanLostHeaderBg ?? this.kanbanLostHeaderBg,
      kanbanLostHeaderFg: kanbanLostHeaderFg ?? this.kanbanLostHeaderFg,
      selectionSoftBg: selectionSoftBg ?? this.selectionSoftBg,
      splashA: splashA ?? this.splashA,
      splashB: splashB ?? this.splashB,
      splashC: splashC ?? this.splashC,
      warningBannerBg: warningBannerBg ?? this.warningBannerBg,
      warningBannerBorder: warningBannerBorder ?? this.warningBannerBorder,
      warningBannerTitle: warningBannerTitle ?? this.warningBannerTitle,
      warningBannerBody: warningBannerBody ?? this.warningBannerBody,
      chatBubbleOtherBg: chatBubbleOtherBg ?? this.chatBubbleOtherBg,
      chatBubbleOtherBorder:
          chatBubbleOtherBorder ?? this.chatBubbleOtherBorder,
      statusOpenBg: statusOpenBg ?? this.statusOpenBg,
      statusOpenFg: statusOpenFg ?? this.statusOpenFg,
      statusWonBg: statusWonBg ?? this.statusWonBg,
      statusWonFg: statusWonFg ?? this.statusWonFg,
      statusLostBg: statusLostBg ?? this.statusLostBg,
      statusLostFg: statusLostFg ?? this.statusLostFg,
      otpCaret: otpCaret ?? this.otpCaret,
      mediaPlaceholderBg: mediaPlaceholderBg ?? this.mediaPlaceholderBg,
      subtleAccentBg: subtleAccentBg ?? this.subtleAccentBg,
      subtleAccentBorder: subtleAccentBorder ?? this.subtleAccentBorder,
      sidebarGradientTop: sidebarGradientTop ?? this.sidebarGradientTop,
      sidebarGradientBottom:
          sidebarGradientBottom ?? this.sidebarGradientBottom,
      sidebarEdge: sidebarEdge ?? this.sidebarEdge,
      sidebarLogoBackdrop: sidebarLogoBackdrop ?? this.sidebarLogoBackdrop,
      sidebarForeground: sidebarForeground ?? this.sidebarForeground,
      sidebarTileSelected: sidebarTileSelected ?? this.sidebarTileSelected,
      sidebarTileBorderActive:
          sidebarTileBorderActive ?? this.sidebarTileBorderActive,
      sidebarTileBorderIdle:
          sidebarTileBorderIdle ?? this.sidebarTileBorderIdle,
    );
  }

  @override
  ThemeExtension<AlmaTokens> lerp(ThemeExtension<AlmaTokens>? other, double t) {
    if (other is! AlmaTokens) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AlmaTokens(
      scaffoldBg: l(scaffoldBg, other.scaffoldBg),
      surface: l(surface, other.surface),
      surfaceVariant: l(surfaceVariant, other.surfaceVariant),
      outline: l(outline, other.outline),
      outlineVariant: l(outlineVariant, other.outlineVariant),
      outlineStrong: l(outlineStrong, other.outlineStrong),
      onSurface: l(onSurface, other.onSurface),
      onSurfaceTitle: l(onSurfaceTitle, other.onSurfaceTitle),
      onSurfaceSecondary: l(onSurfaceSecondary, other.onSurfaceSecondary),
      onSurfaceTertiary: l(onSurfaceTertiary, other.onSurfaceTertiary),
      onSurfaceHint: l(onSurfaceHint, other.onSurfaceHint),
      divider: l(divider, other.divider),
      inputFill: l(inputFill, other.inputFill),
      modalBarrier: l(modalBarrier, other.modalBarrier),
      shadowBase: l(shadowBase, other.shadowBase),
      bottomSheetBg: l(bottomSheetBg, other.bottomSheetBg),
      kanbanOpenHeaderBg: l(kanbanOpenHeaderBg, other.kanbanOpenHeaderBg),
      kanbanOpenHeaderFg: l(kanbanOpenHeaderFg, other.kanbanOpenHeaderFg),
      kanbanWonHeaderBg: l(kanbanWonHeaderBg, other.kanbanWonHeaderBg),
      kanbanWonHeaderFg: l(kanbanWonHeaderFg, other.kanbanWonHeaderFg),
      kanbanLostHeaderBg: l(kanbanLostHeaderBg, other.kanbanLostHeaderBg),
      kanbanLostHeaderFg: l(kanbanLostHeaderFg, other.kanbanLostHeaderFg),
      selectionSoftBg: l(selectionSoftBg, other.selectionSoftBg),
      splashA: l(splashA, other.splashA),
      splashB: l(splashB, other.splashB),
      splashC: l(splashC, other.splashC),
      warningBannerBg: l(warningBannerBg, other.warningBannerBg),
      warningBannerBorder: l(warningBannerBorder, other.warningBannerBorder),
      warningBannerTitle: l(warningBannerTitle, other.warningBannerTitle),
      warningBannerBody: l(warningBannerBody, other.warningBannerBody),
      chatBubbleOtherBg: l(chatBubbleOtherBg, other.chatBubbleOtherBg),
      chatBubbleOtherBorder:
          l(chatBubbleOtherBorder, other.chatBubbleOtherBorder),
      statusOpenBg: l(statusOpenBg, other.statusOpenBg),
      statusOpenFg: l(statusOpenFg, other.statusOpenFg),
      statusWonBg: l(statusWonBg, other.statusWonBg),
      statusWonFg: l(statusWonFg, other.statusWonFg),
      statusLostBg: l(statusLostBg, other.statusLostBg),
      statusLostFg: l(statusLostFg, other.statusLostFg),
      otpCaret: l(otpCaret, other.otpCaret),
      mediaPlaceholderBg: l(mediaPlaceholderBg, other.mediaPlaceholderBg),
      subtleAccentBg: l(subtleAccentBg, other.subtleAccentBg),
      subtleAccentBorder: l(subtleAccentBorder, other.subtleAccentBorder),
      sidebarGradientTop: l(sidebarGradientTop, other.sidebarGradientTop),
      sidebarGradientBottom:
          l(sidebarGradientBottom, other.sidebarGradientBottom),
      sidebarEdge: l(sidebarEdge, other.sidebarEdge),
      sidebarLogoBackdrop: l(sidebarLogoBackdrop, other.sidebarLogoBackdrop),
      sidebarForeground: l(sidebarForeground, other.sidebarForeground),
      sidebarTileSelected: l(sidebarTileSelected, other.sidebarTileSelected),
      sidebarTileBorderActive:
          l(sidebarTileBorderActive, other.sidebarTileBorderActive),
      sidebarTileBorderIdle:
          l(sidebarTileBorderIdle, other.sidebarTileBorderIdle),
    );
  }
}

extension AlmaThemeContext on BuildContext {
  AlmaTokens get alma => Theme.of(this).extension<AlmaTokens>() ?? AlmaTokens.fallback;
}

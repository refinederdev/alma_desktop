import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Desktop layout: ScreenUtil canvas + window bounds (1440×900 design, 720p min).
abstract final class AppDesktopLayout {
  /// ScreenUtil artboard: 1440×900 — common laptop / design reference (16:10).
  static const Size designSize = Size(1440, 900);

  /// Initial window matches the design canvas for predictable .w / .h / .sp scale.
  static const Size defaultWindowSize = Size(1440, 900);

  /// Do not shrink below 1280×720 (HD) so layouts stay usable.
  static const Size minimumWindowSize = Size(1280, 720);

  static const String windowTitle = 'ALMA CRM';
}

bool get _isDesktopHost =>
    Platform.isLinux || Platform.isMacOS || Platform.isWindows;

Future<void> initDesktopWindow() async {
  if (!_isDesktopHost) return;

  await windowManager.ensureInitialized();

  const options = WindowOptions(
    size: AppDesktopLayout.defaultWindowSize,
    minimumSize: AppDesktopLayout.minimumWindowSize,
    center: true,
    title: AppDesktopLayout.windowTitle,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

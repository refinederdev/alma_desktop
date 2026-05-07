import 'dart:async';

import 'package:alma_desktop/app.dart';
import 'package:alma_desktop/core/config/desktop_window.dart';
import 'package:alma_desktop/core/config/injector_container.dart';
import 'package:alma_desktop/core/services/windows_crash_logger/windows_crash_logger.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  await WindowsCrashLogger.instance.initialize();

  runZonedGuarded(
    () async {
      await initDesktopWindow();
      await InjectorContainer.init();
      runApp(const MainApp());
    },
    (error, stackTrace) {
      unawaited(
        WindowsCrashLogger.instance.logError(
          source: 'runZonedGuarded',
          error: error,
          stackTrace: stackTrace,
        ),
      );
    },
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const App();
  }
}

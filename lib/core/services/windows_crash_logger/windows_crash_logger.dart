import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class WindowsCrashLogger {
  WindowsCrashLogger._();

  static final WindowsCrashLogger instance = WindowsCrashLogger._();
  bool _initialized = false;

  Future<void> initialize() async {
    if (!Platform.isWindows || _initialized) return;
    _initialized = true;

    final previousFlutterOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      unawaited(
        logError(
          source: 'FlutterError',
          error: details.exception,
          stackTrace: details.stack,
          context: details.context?.toDescription(),
        ),
      );
      previousFlutterOnError?.call(details);
    };

    final previousPlatformOnError = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      unawaited(
        logError(
          source: 'PlatformDispatcher',
          error: error,
          stackTrace: stack,
        ),
      );
      if (previousPlatformOnError != null) {
        return previousPlatformOnError(error, stack);
      }
      return true;
    };
  }

  Future<void> logError({
    required String source,
    required Object error,
    StackTrace? stackTrace,
    String? context,
  }) async {
    if (!Platform.isWindows) return;
    try {
      final file = await _resolveLogFile();
      final now = DateTime.now().toIso8601String();
      final os = Platform.operatingSystemVersion;
      final appVersion = Platform.version;
      final payload = StringBuffer()
        ..writeln('[$now] $source')
        ..writeln('OS: $os')
        ..writeln('Dart: $appVersion')
        ..writeln('Error: $error');
      if (context != null && context.trim().isNotEmpty) {
        payload.writeln('Context: $context');
      }
      if (stackTrace != null) {
        payload.writeln('StackTrace:\n$stackTrace');
      }
      payload.writeln('----------------------------------------');

      await file.writeAsString(
        payload.toString(),
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {
      // Never throw from logger.
    }
  }

  Future<File> _resolveLogFile() async {
    final baseDir = await _resolveWritableDirectory();
    final logsDir = Directory(
      '${baseDir.path}${Platform.pathSeparator}logs',
    );
    if (!logsDir.existsSync()) {
      logsDir.createSync(recursive: true);
    }
    return File('${logsDir.path}${Platform.pathSeparator}windows_crash.log');
  }

  Future<Directory> _resolveWritableDirectory() async {
    try {
      final support = await getApplicationSupportDirectory();
      if (_canWrite(support)) return support;
    } catch (_) {}

    try {
      final docs = await getApplicationDocumentsDirectory();
      if (_canWrite(docs)) return docs;
    } catch (_) {}

    return Directory.systemTemp;
  }

  bool _canWrite(Directory dir) {
    try {
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final probe = File(
        '${dir.path}${Platform.pathSeparator}.alma_write_probe',
      );
      probe.writeAsStringSync('ok', flush: true);
      if (probe.existsSync()) {
        probe.deleteSync();
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

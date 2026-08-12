import 'dart:io';

import 'package:flutter/services.dart';

class CallComplianceRecording {
  const CallComplianceRecording({
    required this.path,
    required this.durationMs,
    required this.mimeType,
  });

  final String path;
  final int durationMs;
  final String mimeType;

  factory CallComplianceRecording.fromMap(Map<Object?, Object?> map) {
    return CallComplianceRecording(
      path: map['path'] as String,
      durationMs: (map['duration_ms'] as num?)?.toInt() ?? 0,
      mimeType: map['mime_type'] as String? ?? 'audio/mp4',
    );
  }
}

class CallComplianceAudio {
  static const MethodChannel _channel = MethodChannel(
    'com.almacrm.call_compliance_audio',
  );

  bool get isSupported => Platform.isMacOS || Platform.isWindows;

  String get _supportedPlatforms => 'macOS and Windows';

  Future<void> armGate() async {
    if (!isSupported) {
      throw UnsupportedError(
        'Compliance audio is only available on $_supportedPlatforms',
      );
    }
    await _channel.invokeMethod<void>('armGate');
  }

  Future<void> begin({
    required bool record,
    String? announcementPath,
    double announcementVolume = 0.9,
  }) async {
    if (!isSupported) {
      throw UnsupportedError(
        'Compliance audio is only available on $_supportedPlatforms',
      );
    }
    await _channel.invokeMethod<void>('begin', <String, Object?>{
      'record': record,
      'announcement_path': ?announcementPath,
      'announcement_volume': announcementVolume.clamp(0.2, 1.0),
    });
  }

  Future<CallComplianceRecording?> stop() async {
    if (!isSupported) return null;
    final result = await _channel.invokeMethod<Map<Object?, Object?>>('stop');
    return result == null ? null : CallComplianceRecording.fromMap(result);
  }

  Future<void> cancel() async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('cancel');
  }
}

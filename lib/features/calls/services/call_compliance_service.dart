import 'dart:async';
import 'dart:io';

import 'package:alma_desktop/core/api/api_consumer.dart';
import 'package:alma_desktop/core/config/app_config.dart';
import 'package:alma_desktop/core/errors/exceptions.dart';
import 'package:call_compliance_audio/call_compliance_audio.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class CallCompliancePolicy {
  const CallCompliancePolicy({
    required this.moduleEnabled,
    required this.recordingEnabled,
    required this.recordingRequired,
    required this.recordingScope,
    required this.announcementEnabled,
    required this.announcementRequired,
    required this.announcementAudioUrl,
    required this.announcementVolume,
  });

  const CallCompliancePolicy.disabled()
    : moduleEnabled = false,
      recordingEnabled = false,
      recordingRequired = false,
      recordingScope = 'all',
      announcementEnabled = false,
      announcementRequired = false,
      announcementAudioUrl = '',
      announcementVolume = 0.9;

  factory CallCompliancePolicy.fromJson(Map<String, dynamic> json) {
    final volume = json['announcement_volume'];
    return CallCompliancePolicy(
      moduleEnabled: json['module_enabled'] == true,
      recordingEnabled: json['recording_enabled'] == true,
      recordingRequired: json['recording_required'] == true,
      recordingScope: json['recording_scope']?.toString() ?? 'all',
      announcementEnabled: json['announcement_enabled'] == true,
      announcementRequired: json['announcement_required'] == true,
      announcementAudioUrl: json['announcement_audio_url']?.toString() ?? '',
      announcementVolume: volume is num
          ? (volume.toDouble() / 100).clamp(0.2, 1.0)
          : 0.9,
    );
  }

  final bool moduleEnabled;
  final bool recordingEnabled;
  final bool recordingRequired;
  final String recordingScope;
  final bool announcementEnabled;
  final bool announcementRequired;
  final String announcementAudioUrl;
  final double announcementVolume;

  bool shouldRecord(String direction) {
    return moduleEnabled &&
        recordingEnabled &&
        (recordingScope == 'all' || recordingScope == direction);
  }

  bool shouldAnnounce(String direction) {
    return shouldRecord(direction) &&
        announcementEnabled &&
        announcementAudioUrl.trim().isNotEmpty;
  }
}

class CallComplianceRequiredException implements Exception {
  const CallComplianceRequiredException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Coordinates the server-owned compliance policy with the native desktop
/// audio path. Meta remains the WebRTC peer; this service only injects the
/// notice locally and uploads the completed recording through the CRM API.
class CallComplianceService {
  CallComplianceService({required this.apiConsumer, required this.dio});

  final ApiConsumer apiConsumer;
  final Dio dio;
  final CallComplianceAudio _nativeAudio = CallComplianceAudio();

  CallCompliancePolicy _policy = const CallCompliancePolicy.disabled();
  DateTime? _policyFetchedAt;
  String? _announcementPath;
  int? _activeCallId;
  bool _recordingActive = false;
  final Set<Future<void>> _pendingUploads = <Future<void>>{};

  CallCompliancePolicy get policy => _policy;
  bool get hasActiveRecording => _recordingActive;

  Future<CallCompliancePolicy> refreshPolicy({bool force = false}) async {
    final fetchedAt = _policyFetchedAt;
    if (!force &&
        fetchedAt != null &&
        DateTime.now().difference(fetchedAt) < const Duration(minutes: 2)) {
      return _policy;
    }

    dynamic response;
    try {
      response = await apiConsumer.get('whatsapp-calls/module-settings');
    } on NotFoundException {
      // Backward compatibility while a desktop release reaches an older CRM
      // backend. Calls must keep working; compliance automatically activates
      // as soon as the backend route is deployed and returns its policy.
      _policy = const CallCompliancePolicy.disabled();
      _policyFetchedAt = DateTime.now();
      if (kDebugMode) {
        // ignore: avoid_print
        print(
          '⚠️ Call compliance API is not deployed; using legacy call mode.',
        );
      }
      return _policy;
    }
    final map = response is Map
        ? Map<String, dynamic>.from(response)
        : const <String, dynamic>{};
    final rawSettings = map['settings'];
    _policy = CallCompliancePolicy.fromJson(
      rawSettings is Map
          ? Map<String, dynamic>.from(rawSettings)
          : const <String, dynamic>{},
    );
    _policyFetchedAt = DateTime.now();
    return _policy;
  }

  /// Prepares the notice before WebRTC is connected and arms a native mic
  /// gate, ensuring no employee speech can leak before the notice.
  Future<void> prepareAndArm(String direction) async {
    try {
      await refreshPolicy(force: true);
    } catch (error) {
      // A previously fetched policy is safe to reuse during a brief network
      // interruption. With no policy at all, fail closed: silently starting
      // an unannounced/unrecorded call could violate the admin requirement.
      if (_policyFetchedAt == null) {
        throw CallComplianceRequiredException(
          'Unable to load the required call recording policy: $error',
        );
      }
      if (kDebugMode) {
        // ignore: avoid_print
        print('⚠️ Call compliance settings unavailable: $error');
      }
    }

    if (!_policy.shouldRecord(direction)) return;
    if (!Platform.isMacOS) {
      if (_policy.recordingRequired) {
        throw const CallComplianceRequiredException(
          'Required call recording is not available on this desktop platform.',
        );
      }
      return;
    }

    if (_policy.shouldAnnounce(direction)) {
      try {
        _announcementPath = await _downloadAnnouncement(
          _policy.announcementAudioUrl,
        );
        await _nativeAudio.armGate();
      } catch (error) {
        _announcementPath = null;
        if (_policy.announcementRequired) {
          throw CallComplianceRequiredException(
            'Unable to prepare the required recording announcement: $error',
          );
        }
        if (kDebugMode) {
          // ignore: avoid_print
          print('⚠️ Optional call announcement unavailable: $error');
        }
      }
    }
  }

  /// Starts the server lifecycle and native capture. The native mic gate stays
  /// closed until the configured announcement has been injected completely.
  Future<void> begin(int callId, String direction) async {
    if (!_policy.shouldRecord(direction) || !Platform.isMacOS) return;
    if (_activeCallId == callId && _recordingActive) return;

    try {
      await apiConsumer.post(
        'whatsapp-calls/$callId/recording/start',
        body: null,
      );
      _activeCallId = callId;
      _recordingActive = true;
      await _nativeAudio.begin(
        record: true,
        announcementPath: _policy.shouldAnnounce(direction)
            ? _announcementPath
            : null,
        announcementVolume: _policy.announcementVolume,
      );
    } catch (error) {
      _activeCallId = null;
      _recordingActive = false;
      await _reportFailure(callId, error);
      await _nativeAudio.cancel();
      if (_policy.recordingRequired || _policy.announcementRequired) {
        throw CallComplianceRequiredException(
          'Required call recording could not start: $error',
        );
      }
      if (kDebugMode) {
        // ignore: avoid_print
        print('⚠️ Optional call recording did not start: $error');
      }
    }
  }

  Future<void> finish(int? callId) async {
    final targetCallId = _activeCallId ?? callId;
    if (!_recordingActive || targetCallId == null) {
      await cancelPrepared();
      return;
    }

    CallComplianceRecording? recording;
    try {
      recording = await _nativeAudio.stop();
      if (recording == null) {
        throw StateError('The desktop audio recorder returned no audio');
      }
    } catch (error) {
      await _reportFailure(targetCallId, error);
      if (kDebugMode) {
        // ignore: avoid_print
        print('❌ Call recording finalization failed: $error');
      }
    } finally {
      _activeCallId = null;
      _recordingActive = false;
      _announcementPath = null;
    }

    // Native capture/export is now fully stopped, so the next queued customer
    // can be answered immediately. Upload proceeds independently with retries.
    if (recording != null) {
      _queueUpload(targetCallId, recording);
    }
  }

  Future<void> waitForPendingUploads() async {
    final pending = List<Future<void>>.from(_pendingUploads);
    if (pending.isNotEmpty) await Future.wait(pending);
  }

  Future<void> cancelPrepared() async {
    if (_recordingActive) return;
    try {
      await _nativeAudio.cancel();
    } catch (_) {}
    _announcementPath = null;
  }

  Future<String> _downloadAnnouncement(String rawUrl) async {
    final uri = Uri.parse(rawUrl);
    final url = uri.hasScheme
        ? rawUrl
        : '${AppConfig.baseUrlWithoutApi}${rawUrl.startsWith('/') ? '' : '/'}$rawUrl';
    final directory = await getTemporaryDirectory();
    final extension = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last.split('.').last
        : 'mp3';
    final target =
        '${directory.path}/alma-call-announcement.${extension.isEmpty ? 'mp3' : extension}';
    await dio.download(
      url,
      target,
      options: Options(receiveTimeout: const Duration(seconds: 30)),
    );
    final file = File(target);
    if (!await file.exists() || await file.length() == 0) {
      throw StateError('Downloaded announcement is empty');
    }
    return target;
  }

  Future<void> _reportFailure(int callId, Object error) async {
    try {
      await apiConsumer.post(
        'whatsapp-calls/$callId/recording/failed',
        body: {'reason': error.toString(), 'client': 'alma-desktop-macos'},
      );
    } catch (_) {}
  }

  Future<void> _uploadWithRetry(
    int callId,
    CallComplianceRecording recording,
  ) async {
    Object? lastError;
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        // FormData/MultipartFile instances cannot be reused after a failed
        // request because Dio may already have consumed their byte stream.
        await apiConsumer.post(
          'whatsapp-calls/$callId/recording',
          isFormData: true,
          body: {
            'recording': await MultipartFile.fromFile(
              recording.path,
              filename: 'whatsapp-call-$callId.m4a',
            ),
            'duration_ms': recording.durationMs,
            'codec': 'audio/mp4;codecs=aac',
            'client': 'alma-desktop-macos',
          },
        );
        return;
      } catch (error) {
        lastError = error;
        if (attempt < 3) {
          await Future<void>.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
    throw lastError ?? StateError('Recording upload failed');
  }

  Future<void> _uploadCompletedRecording(
    int callId,
    CallComplianceRecording recording,
  ) async {
    try {
      await _uploadWithRetry(callId, recording);
      await _deleteIfExists(recording.path);
    } catch (error) {
      await _reportFailure(callId, error);
      if (kDebugMode) {
        // ignore: avoid_print
        print('❌ Call recording upload failed: $error');
      }
      // Keep the M4A in the application temp directory for recovery instead
      // of deleting the only copy after all upload attempts fail.
    }
  }

  void _queueUpload(int callId, CallComplianceRecording recording) {
    late final Future<void> upload;
    upload = _uploadCompletedRecording(callId, recording).whenComplete(() {
      _pendingUploads.remove(upload);
    });
    _pendingUploads.add(upload);
    unawaited(upload);
  }

  Future<void> _deleteIfExists(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}

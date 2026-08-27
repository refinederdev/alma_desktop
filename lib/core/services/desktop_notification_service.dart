import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

abstract interface class NotificationAudioBackend {
  Future<void> initialize();

  Future<void> play();

  Future<void> reset();

  Future<void> dispose();
}

class AudioPoolNotificationBackend implements NotificationAudioBackend {
  AudioPool? _pool;

  @override
  Future<void> initialize() async {
    _pool ??= await AudioPool.createFromAsset(
      path: 'sound/notifi.wav',
      minPlayers: 2,
      maxPlayers: 4,
    );
  }

  @override
  Future<void> play() async {
    await initialize();
    await _pool!.start();
  }

  @override
  Future<void> reset() async {
    final pool = _pool;
    _pool = null;
    await pool?.dispose();
  }

  @override
  Future<void> dispose() => reset();
}

/// App-wide notification sound coordinator.
///
/// Reverb events are observed by both the chat and CRM controllers. Keeping
/// deduplication and audio playback here prevents those listeners from racing
/// each other, while the preloaded pool avoids the delay and stale-player
/// failures caused by repeatedly loading the asset on every event.
class DesktopNotificationService {
  DesktopNotificationService({
    NotificationAudioBackend? audioBackend,
    DateTime Function()? clock,
    this.duplicateWindow = const Duration(seconds: 30),
  }) : _audioBackend = audioBackend ?? AudioPoolNotificationBackend(),
       _clock = clock ?? DateTime.now;

  final NotificationAudioBackend _audioBackend;
  final DateTime Function() _clock;
  final Duration duplicateWindow;

  final Map<String, DateTime> _recentEvents = <String, DateTime>{};
  Future<void>? _initialization;
  bool _disposed = false;

  Future<void> initialize() {
    if (_disposed) return Future<void>.value();
    return _initialization ??= _audioBackend.initialize().catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      _initialization = null;
      if (kDebugMode) {
        debugPrint('Notification audio warm-up failed: $error');
      }
    });
  }

  /// Plays one audible cue for [eventKey]. Duplicate realtime deliveries of
  /// the same event are ignored across every screen in the app.
  Future<bool> notify({required String eventKey}) async {
    if (_disposed || eventKey.trim().isEmpty) return false;

    final now = _clock();
    _recentEvents.removeWhere(
      (_, occurredAt) => now.difference(occurredAt) > duplicateWindow,
    );
    if (_recentEvents.containsKey(eventKey)) return false;
    _recentEvents[eventKey] = now;

    try {
      await initialize();
      await _audioBackend.play();
      return true;
    } catch (firstError) {
      // A native player may become invalid after sleep, device switching, or
      // rapid overlapping events. Rebuild once and replay the cue.
      try {
        _initialization = null;
        await _audioBackend.reset();
        await initialize();
        await _audioBackend.play();
        return true;
      } catch (retryError) {
        _recentEvents.remove(eventKey);
        if (kDebugMode) {
          debugPrint(
            'Notification audio failed after recovery: '
            '$firstError; retry: $retryError',
          );
        }
        return false;
      }
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _recentEvents.clear();
    await _audioBackend.dispose();
  }
}

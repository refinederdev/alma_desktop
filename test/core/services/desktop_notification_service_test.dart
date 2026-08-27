import 'package:alma_desktop/core/services/desktop_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DesktopNotificationService', () {
    test('deduplicates the same realtime event across listeners', () async {
      final backend = _FakeAudioBackend();
      final service = DesktopNotificationService(audioBackend: backend);

      final first = await service.notify(eventKey: 'message:4:wa-10');
      final duplicate = await service.notify(eventKey: 'message:4:wa-10');

      expect(first, isTrue);
      expect(duplicate, isFalse);
      expect(backend.playCalls, 1);
      await service.dispose();
    });

    test('allows the same event again after the duplicate window', () async {
      final backend = _FakeAudioBackend();
      var now = DateTime(2026, 8, 27, 12);
      final service = DesktopNotificationService(
        audioBackend: backend,
        clock: () => now,
        duplicateWindow: const Duration(seconds: 5),
      );

      await service.notify(eventKey: 'message:4:wa-10');
      now = now.add(const Duration(seconds: 6));
      final replayed = await service.notify(eventKey: 'message:4:wa-10');

      expect(replayed, isTrue);
      expect(backend.playCalls, 2);
      await service.dispose();
    });

    test('rebuilds the audio backend and retries one failed play', () async {
      final backend = _FakeAudioBackend(failFirstPlay: true);
      final service = DesktopNotificationService(audioBackend: backend);

      final played = await service.notify(eventKey: 'message:9:wa-99');

      expect(played, isTrue);
      expect(backend.playCalls, 2);
      expect(backend.resetCalls, 1);
      expect(backend.initializeCalls, 2);
      await service.dispose();
    });

    test(
      'does not permanently deduplicate an event when recovery fails',
      () async {
        final backend = _FakeAudioBackend(alwaysFail: true);
        final service = DesktopNotificationService(audioBackend: backend);

        expect(await service.notify(eventKey: 'message:2:wa-7'), isFalse);
        expect(await service.notify(eventKey: 'message:2:wa-7'), isFalse);

        expect(backend.playCalls, 4);
        await service.dispose();
      },
    );
  });
}

class _FakeAudioBackend implements NotificationAudioBackend {
  _FakeAudioBackend({this.failFirstPlay = false, this.alwaysFail = false});

  final bool failFirstPlay;
  final bool alwaysFail;

  int initializeCalls = 0;
  int playCalls = 0;
  int resetCalls = 0;

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  Future<void> play() async {
    playCalls++;
    if (alwaysFail || (failFirstPlay && playCalls == 1)) {
      throw StateError('native player failed');
    }
  }

  @override
  Future<void> reset() async {
    resetCalls++;
  }

  @override
  Future<void> dispose() async {}
}

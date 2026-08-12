import 'package:alma_desktop/core/api/api_consumer.dart';
import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/features/calls/data/datasources/calls_remote_data_source.dart';
import 'package:alma_desktop/features/calls/data/models/call_permission_model.dart';
import 'package:alma_desktop/features/calls/data/models/whatsapp_call_model.dart';
import 'package:alma_desktop/features/calls/domain/entities/call_event.dart';
import 'package:alma_desktop/features/calls/presentation/controllers/call_controller.dart';
import 'package:alma_desktop/features/calls/services/whatsapp_webrtc_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WhatsApp calling backend contract', () {
    test('uses the calling settings and enable endpoints', () async {
      final api = _RecordingApiConsumer();
      final source = CallsRemoteDataSourceImpl(apiConsumer: api);

      final settings = await source.getCallingSettings(7);
      await source.setCallingEnabled(7, enabled: true);

      expect(settings['calling_enabled'], isFalse);
      expect(api.getPaths, ['whatsapp-calls/sessions/7/settings']);
      expect(api.postPaths, ['whatsapp-calls/sessions/7/enable']);
    });

    test('parses normalized permission state returned by the backend', () {
      final permission = CallPermissionModel.fromJson({
        'granted': true,
        'state': 'temporary',
        'expires_at': 1786500000,
      });

      expect(permission.granted, isTrue);
      expect(permission.state, 'temporary');
      expect(permission.expiresAt, isNotNull);
    });

    test('recognizes current Meta calling error codes', () {
      final permission = CallFailureInfo.fromFailure(
        const ServerFailure(
          message: 'Call API Error (138006): No approved call permission',
        ),
        'fallback',
      );
      final disabled = CallFailureInfo.fromFailure(
        const ServerFailure(
          message: 'Call API Error (138000): Calling not enabled',
        ),
        'fallback',
      );

      expect(permission.isPermissionRequired, isTrue);
      expect(permission.metaCode, CallMetaError.permissionRequired);
      expect(disabled.isCallingDisabled, isTrue);
      expect(disabled.metaCode, CallMetaError.callingNotEnabled);
    });

    test('parses multi-agent ownership and claimed realtime events', () {
      final call = WhatsAppCallModel.fromJson({
        'id': 44,
        'direction': 'inbound',
        'status': 'connecting',
        'accepted_by_user_id': 9,
        'accepted_at': '2026-08-12T20:00:00Z',
        'is_claimed_by_me': true,
      });

      expect(
        CallEventType.fromString('call_claimed'),
        CallEventType.callClaimed,
      );
      expect(call.acceptedByUserId, 9);
      expect(call.isClaimedByMe, isTrue);
      expect(call.acceptedAt, isNotNull);
    });
  });

  group('SDP transport safety', () {
    test('normalizes mixed line endings and preserves final CRLF', () {
      final normalized = WhatsAppWebRtcService.normalizeSdp(
        'v=0\no=- 1 2 IN IP4 127.0.0.1\r\ns=-   \r\nt=0 0',
      );

      expect(normalized, 'v=0\r\no=- 1 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\n');
      expect(normalized.endsWith('\r\n'), isTrue);
      expect(RegExp(r'(?<!\r)\n').hasMatch(normalized), isFalse);
    });
  });
}

class _RecordingApiConsumer implements ApiConsumer {
  final List<String> getPaths = [];
  final List<String> postPaths = [];

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    getPaths.add(path);
    return {'session_id': 7, 'calling_enabled': false};
  }

  @override
  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool? isFormData,
  }) async {
    postPaths.add(path);
    return {'session_id': 7, 'calling_enabled': true};
  }

  @override
  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) => throw UnimplementedError();

  @override
  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool? isFormData,
  }) => throw UnimplementedError();

  @override
  Future<dynamic> request(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool? isFormData = false,
    dynamic options,
  }) => throw UnimplementedError();
}

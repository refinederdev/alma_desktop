import 'package:alma_desktop/core/api/api_consumer.dart';
import 'package:alma_desktop/core/services/paginator/paginator.dart';
import 'package:alma_desktop/features/calls/data/models/call_permission_model.dart';
import 'package:alma_desktop/features/calls/data/models/call_sessions_response_model.dart';
import 'package:alma_desktop/features/calls/data/models/whatsapp_call_model.dart';

abstract class CallsRemoteDataSource {
  Future<CallSessionsResponseModel> getSessions();

  Future<Map<String, dynamic>> setCallingEnabled(
    int sessionId, {
    required bool enabled,
  });

  Future<WhatsAppCallModel?> getActiveCall(int sessionId);

  Future<WhatsAppCallModel> getCallById(
    int callId, {
    bool includeSdp = false,
  });

  Future<WhatsAppCallModel> getCallSdp(int callId);

  Future<PaginatorModel<WhatsAppCallModel>> getCallHistory({
    required int sessionId,
    int page = 1,
    int perPage = 20,
    String? direction,
    String? status,
    int? dealId,
  });

  Future<WhatsAppCallModel> initiateCall({
    required int sessionId,
    required String to,
    required String sdpOffer,
  });

  Future<WhatsAppCallModel> acceptCall({
    required int callId,
    required String sdpAnswer,
  });

  Future<WhatsAppCallModel> preAcceptCall({
    required int callId,
    required String sdpAnswer,
  });

  Future<WhatsAppCallModel> rejectCall(int callId);

  Future<WhatsAppCallModel> terminateCall(int callId);

  Future<CallPermissionModel> checkPermission({
    required int sessionId,
    required String userPhone,
  });

  Future<CallPermissionModel> requestPermission({
    required int sessionId,
    required String to,
    String? templateName,
    String? languageCode,
  });
}

class CallsRemoteDataSourceImpl implements CallsRemoteDataSource {
  final ApiConsumer apiConsumer;

  CallsRemoteDataSourceImpl({required this.apiConsumer});

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    return <String, dynamic>{};
  }

  WhatsAppCallModel _parseCallFrom(dynamic raw) {
    final map = _asMap(raw);
    final inner = map['call'];
    if (inner is Map<String, dynamic>) {
      return WhatsAppCallModel.fromJson(inner);
    }
    return WhatsAppCallModel.fromJson(map);
  }

  @override
  Future<CallSessionsResponseModel> getSessions() async {
    final response = await apiConsumer.get('whatsapp-calls/sessions');
    return CallSessionsResponseModel.fromJson(_asMap(response));
  }

  @override
  Future<Map<String, dynamic>> setCallingEnabled(
    int sessionId, {
    required bool enabled,
  }) async {
    final path = enabled
        ? 'whatsapp-calls/sessions/$sessionId/enable'
        : 'whatsapp-calls/sessions/$sessionId/disable';
    final response = await apiConsumer.post(path, body: null);
    return _asMap(response);
  }

  @override
  Future<WhatsAppCallModel?> getActiveCall(int sessionId) async {
    final response = await apiConsumer.get(
      'whatsapp-calls/active',
      queryParameters: {'session_id': sessionId},
    );
    final map = _asMap(response);
    final inner = map['call'];
    if (inner == null) return null;
    if (inner is Map<String, dynamic>) {
      return WhatsAppCallModel.fromJson(inner);
    }
    return null;
  }

  @override
  Future<WhatsAppCallModel> getCallById(
    int callId, {
    bool includeSdp = false,
  }) async {
    final response = await apiConsumer.get(
      'whatsapp-calls/$callId',
      queryParameters: includeSdp ? {'include_sdp': 1} : null,
    );
    return _parseCallFrom(response);
  }

  @override
  Future<WhatsAppCallModel> getCallSdp(int callId) async {
    final response = await apiConsumer.get('whatsapp-calls/$callId/sdp');
    return _parseCallFrom(response);
  }

  @override
  Future<PaginatorModel<WhatsAppCallModel>> getCallHistory({
    required int sessionId,
    int page = 1,
    int perPage = 20,
    String? direction,
    String? status,
    int? dealId,
  }) async {
    final query = <String, dynamic>{
      'session_id': sessionId,
      'page': page,
      'per_page': perPage,
    };
    if (direction != null) query['direction'] = direction;
    if (status != null) query['status'] = status;
    if (dealId != null) query['deal_id'] = dealId;

    final response = await apiConsumer.get(
      'whatsapp-calls/history',
      queryParameters: query,
    );
    return PaginatorModel<WhatsAppCallModel>.fromJson(
      _asMap(response),
      (m) => WhatsAppCallModel.fromJson(m),
    );
  }

  @override
  Future<WhatsAppCallModel> initiateCall({
    required int sessionId,
    required String to,
    required String sdpOffer,
  }) async {
    final response = await apiConsumer.post(
      'whatsapp-calls/initiate',
      body: {
        'session_id': sessionId,
        'to': to,
        'sdp_offer': sdpOffer,
      },
    );
    return _parseCallFrom(response);
  }

  @override
  Future<WhatsAppCallModel> acceptCall({
    required int callId,
    required String sdpAnswer,
  }) async {
    final response = await apiConsumer.post(
      'whatsapp-calls/$callId/accept',
      body: {'sdp_answer': sdpAnswer},
    );
    return _parseCallFrom(response);
  }

  @override
  Future<WhatsAppCallModel> preAcceptCall({
    required int callId,
    required String sdpAnswer,
  }) async {
    final response = await apiConsumer.post(
      'whatsapp-calls/$callId/pre-accept',
      body: {'sdp_answer': sdpAnswer},
    );
    return _parseCallFrom(response);
  }

  @override
  Future<WhatsAppCallModel> rejectCall(int callId) async {
    final response = await apiConsumer.post(
      'whatsapp-calls/$callId/reject',
      body: null,
    );
    return _parseCallFrom(response);
  }

  @override
  Future<WhatsAppCallModel> terminateCall(int callId) async {
    final response = await apiConsumer.post(
      'whatsapp-calls/$callId/terminate',
      body: null,
    );
    return _parseCallFrom(response);
  }

  @override
  Future<CallPermissionModel> checkPermission({
    required int sessionId,
    required String userPhone,
  }) async {
    final response = await apiConsumer.post(
      'whatsapp-calls/permissions/check',
      body: {
        'session_id': sessionId,
        'user_phone': userPhone,
      },
    );
    return CallPermissionModel.fromJson(_asMap(response));
  }

  @override
  Future<CallPermissionModel> requestPermission({
    required int sessionId,
    required String to,
    String? templateName,
    String? languageCode,
  }) async {
    final body = <String, dynamic>{
      'session_id': sessionId,
      'to': to,
    };
    if (templateName != null) body['template_name'] = templateName;
    if (languageCode != null) body['language_code'] = languageCode;

    final response = await apiConsumer.post(
      'whatsapp-calls/permissions/request',
      body: body,
    );
    return CallPermissionModel.fromJson(_asMap(response));
  }
}

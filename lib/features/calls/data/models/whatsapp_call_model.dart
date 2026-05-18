import 'package:alma_desktop/features/calls/domain/entities/whatsapp_call.dart';

class WhatsAppCallModel extends WhatsAppCall {
  const WhatsAppCallModel({
    required super.id,
    super.callId,
    required super.direction,
    required super.status,
    super.sessionId,
    super.callerPhone,
    super.calleePhone,
    super.remotePhone,
    super.duration,
    super.durationSeconds,
    super.dealId,
    super.contactName,
    super.sdpOffer,
    super.sdpAnswer,
    super.startedAt,
    super.endedAt,
    super.createdAt,
  });

  factory WhatsAppCallModel.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    DateTime? toDate(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) {
        try {
          return DateTime.parse(v).toUtc().toLocal();
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return WhatsAppCallModel(
      id: toInt(json['id']) ?? 0,
      callId: json['call_id'] as String?,
      direction: (json['direction'] as String?) ?? 'outbound',
      status: (json['status'] as String?) ?? 'pending',
      sessionId: toInt(json['session_id']) ?? toInt(json['crm_session_id']),
      callerPhone: json['caller_phone'] as String?,
      calleePhone: json['callee_phone'] as String?,
      remotePhone: json['remote_phone'] as String?,
      duration: json['duration'] as String?,
      durationSeconds: toInt(json['duration_seconds']),
      dealId: toInt(json['deal_id']),
      contactName: json['contact_name'] as String?,
      sdpOffer: json['sdp_offer'] as String?,
      sdpAnswer: json['sdp_answer'] as String?,
      startedAt: toDate(json['started_at']),
      endedAt: toDate(json['ended_at']),
      createdAt: toDate(json['created_at']),
    );
  }
}

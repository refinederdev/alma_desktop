import 'package:alma_desktop/features/calls/domain/entities/call_session.dart';

class CallSessionModel extends CallSession {
  const CallSessionModel({
    required super.id,
    super.sessionName,
    super.phoneNumber,
    super.phoneNumberId,
    super.status,
    super.realtimeChannel,
  });

  factory CallSessionModel.fromJson(Map<String, dynamic> json) =>
      CallSessionModel(
        id: (json['id'] as num).toInt(),
        sessionName: json['session_name'] as String?,
        phoneNumber: json['phone_number'] as String?,
        phoneNumberId: json['phone_number_id']?.toString(),
        status: json['status'] as String?,
        realtimeChannel: json['realtime_channel'] as String?,
      );
}

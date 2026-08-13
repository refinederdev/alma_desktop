import 'package:alma_desktop/features/main/domain/entities/crm_session.dart';

class CrmSessionModel extends CrmSession {
  static final DateTime _unknownTimestamp = DateTime.fromMillisecondsSinceEpoch(
    0,
    isUtc: true,
  );

  const CrmSessionModel({
    required super.id,
    required super.sessionId,
    required super.userId,
    required super.contactGroupId,
    super.sessionName,
    super.phoneNumber,
    required super.apiKey,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
  }) : super();

  factory CrmSessionModel.fromJson(Map<String, dynamic> json) =>
      CrmSessionModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        sessionId: json['session_id'] as String? ?? '',
        // Deals endpoints embed a compact session that intentionally omits
        // ownership, API credentials, and audit timestamps.
        userId: (json['user_id'] as num?)?.toInt() ?? 0,
        contactGroupId: (json['contact_group_id'] as num?)?.toInt() ?? 0,
        sessionName: json['session_name'] as String?,
        phoneNumber: json['phone_number'] as String?,
        apiKey: json['api_key'] as String? ?? '',
        status: json['status'] as String? ?? 'active',
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
            _unknownTimestamp,
        updatedAt:
            DateTime.tryParse(json['updated_at'] as String? ?? '') ??
            _unknownTimestamp,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'session_id': sessionId,
    'user_id': userId,
    'contact_group_id': contactGroupId,
    'session_name': sessionName,
    'phone_number': phoneNumber,
    'api_key': apiKey,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

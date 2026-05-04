import 'package:alma_desktop/features/main/domain/entities/crm_session.dart';

class CrmSessionModel extends CrmSession {
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
        id: json['id'] as int,
        sessionId: json['session_id'] as String? ?? '',
        userId: json['user_id'] as int,
        contactGroupId: json['contact_group_id'] as int? ?? 0,
        sessionName: json['session_name'] as String?,
        phoneNumber: json['phone_number'] as String?,
        apiKey: json['api_key'] as String? ?? '',
        status: json['status'] as String? ?? 'active',
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
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

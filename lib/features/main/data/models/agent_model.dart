import 'package:alma_desktop/features/main/domain/entities/agent.dart';

class AgentModel extends Agent {
  const AgentModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.fullName,
    required super.email,
    required super.phone,
    required super.language,
    required super.isActive,
    super.emailVerifiedAt,
    required super.avatar,
    required super.roles,
    required super.createdAt,
    required super.updatedAt,
  }) : super();

  factory AgentModel.fromJson(Map<String, dynamic> json) => AgentModel(
    id: json['id'] as int,
    firstName: json['first_name'] as String,
    lastName: json['last_name'] as String,
    fullName: json['full_name'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String,
    language: json['language'] as String,
    isActive: json['is_active'] as bool? ?? false,
    emailVerifiedAt: json['email_verified_at'] != null
        ? DateTime.parse(json['email_verified_at'] as String)
        : null,
    avatar: json['avatar'] as String? ?? '',
    roles:
        (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ??
        [],
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'language': language,
    'is_active': isActive,
    'email_verified_at': emailVerifiedAt?.toIso8601String(),
    'avatar': avatar,
    'roles': roles,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

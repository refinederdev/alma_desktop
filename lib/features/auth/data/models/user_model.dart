import 'package:alma_desktop/features/auth/domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.fullName,
    required super.email,
    required super.phone,
    required super.language,
    required super.isActive,
    super.emailVerifiedAt,
    super.avatar,
    required super.roles,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      language: json['language'] as String,
      isActive: json['is_active'] as bool,
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'] as String)
          : null,
      avatar: json['avatar'] as String?,
      roles: json['roles'] != null
          ? (json['roles'] as List<dynamic>)
                .map((role) => role as String)
                .toList()
          : <String>[],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
}

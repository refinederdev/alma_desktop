import 'package:equatable/equatable.dart';

class DealUser extends Equatable {
  final int id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String phone;
  final String language;
  final bool isActive;
  final DateTime? emailVerifiedAt;
  final String? avatar;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DealUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.language,
    required this.isActive,
    this.emailVerifiedAt,
    this.avatar,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        fullName,
        email,
        phone,
        language,
        isActive,
        emailVerifiedAt,
        avatar,
        createdAt,
        updatedAt,
      ];
}

import 'package:equatable/equatable.dart';

class CrmSession extends Equatable {
  final int id;
  final String sessionId;
  final int userId;
  final int contactGroupId;
  final String? sessionName;
  final String? phoneNumber;
  final String apiKey;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CrmSession({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.contactGroupId,
    this.sessionName,
    this.phoneNumber,
    required this.apiKey,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        sessionId,
        userId,
        contactGroupId,
        sessionName,
        phoneNumber,
        apiKey,
        status,
        createdAt,
        updatedAt,
      ];
}

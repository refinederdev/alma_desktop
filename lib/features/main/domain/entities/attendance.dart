import 'package:alma_desktop/features/auth/domain/entities/user.dart';
import 'package:equatable/equatable.dart';

class Attendance extends Equatable {
  final int id;
  final int userId;
  final DateTime? clockInAt;
  final DateTime? clockOutAt;
  final DateTime date;
  final int? totalSeconds;
  final String? formattedTotalTime;
  final String? notes;
  final String status; // 'checked_in' or 'checked_out'
  final bool isClockedIn;
  final User? user;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Attendance({
    required this.id,
    required this.userId,
    this.clockInAt,
    this.clockOutAt,
    required this.date,
    this.totalSeconds,
    this.formattedTotalTime,
    this.notes,
    required this.status,
    required this.isClockedIn,
    this.user,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    clockInAt,
    clockOutAt,
    date,
    totalSeconds,
    formattedTotalTime,
    notes,
    status,
    isClockedIn,
    user,
    createdAt,
    updatedAt,
  ];
}

import 'package:alma_desktop/features/auth/data/models/user_model.dart';
import 'package:alma_desktop/features/main/domain/entities/attendance.dart';

class AttendanceModel extends Attendance {
  const AttendanceModel({
    required super.id,
    required super.userId,
    super.clockInAt,
    super.clockOutAt,
    required super.date,
    super.totalSeconds,
    super.formattedTotalTime,
    super.notes,
    required super.status,
    required super.isClockedIn,
    super.user,
    required super.createdAt,
    required super.updatedAt,
  }) : super();

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    // تحديد حالة الحضور بناءً على status
    final statusString = json['status'] as String? ?? 'checked_out';
    final isClockedInValue =
        statusString == 'checked_in' ||
        (json['is_clocked_in'] as bool?) == true;

    // استخدام قيم افتراضية عندما لا يكون هناك سجل حضور كامل
    final now = DateTime.now();

    return AttendanceModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      clockInAt: json['clock_in_at'] != null
          ? DateTime.parse(json['clock_in_at'] as String)
          : null,
      clockOutAt: json['clock_out_at'] != null
          ? DateTime.parse(json['clock_out_at'] as String)
          : null,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      totalSeconds: json['total_seconds'] as int?,
      formattedTotalTime: json['formatted_total_time'] as String?,
      notes: json['notes'] as String?,
      status: statusString,
      isClockedIn: isClockedInValue,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : now,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : now,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'clock_in_at': clockInAt?.toIso8601String(),
      'clock_out_at': clockOutAt?.toIso8601String(),
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'total_seconds': totalSeconds,
      'formatted_total_time': formattedTotalTime,
      'notes': notes,
      'status': status,
      'is_clocked_in': isClockedIn,
      'user': user != null && user is UserModel
          ? (user! as UserModel).toJson()
          : null,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

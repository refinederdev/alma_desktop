import 'package:alma_desktop/features/main/domain/entities/attendance_time_total.dart';

class AttendanceTimeTotalModel extends AttendanceTimeTotal {
  const AttendanceTimeTotalModel({
    required super.totalSeconds,
    required super.formattedTotalTime,
  }) : super();

  factory AttendanceTimeTotalModel.fromJson(Map<String, dynamic> json) {
    return AttendanceTimeTotalModel(
      totalSeconds: (json['total_seconds'] as num?)?.toDouble() ?? 0.0,
      formattedTotalTime: json['formatted_total_time'] as String? ?? '00:00:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_seconds': totalSeconds,
      'formatted_total_time': formattedTotalTime,
    };
  }
}

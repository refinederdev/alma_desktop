import 'package:alma_desktop/features/main/domain/entities/attendance_weekly_stat.dart';

class AttendanceWeeklyStatModel extends AttendanceWeeklyStat {
  const AttendanceWeeklyStatModel({
    required super.day,
    required super.hours,
    required super.date,
  }) : super();

  factory AttendanceWeeklyStatModel.fromJson(Map<String, dynamic> json) {
    return AttendanceWeeklyStatModel(
      day: json['day'] as String? ?? '',
      hours: (json['hours'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'day': day, 'hours': hours, 'date': date};
  }
}

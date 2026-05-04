import 'package:equatable/equatable.dart';

class AttendanceWeeklyStat extends Equatable {
  final String day;
  final double hours;
  final String date;

  const AttendanceWeeklyStat({
    required this.day,
    required this.hours,
    required this.date,
  });

  @override
  List<Object?> get props => [day, hours, date];
}

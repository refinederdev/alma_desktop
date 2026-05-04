import 'package:equatable/equatable.dart';

class AttendanceTimeTotal extends Equatable {
  final double totalSeconds;
  final String formattedTotalTime;

  const AttendanceTimeTotal({
    required this.totalSeconds,
    required this.formattedTotalTime,
  });

  @override
  List<Object?> get props => [totalSeconds, formattedTotalTime];
}

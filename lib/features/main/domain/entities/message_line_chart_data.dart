import 'package:equatable/equatable.dart';

class MessageLineChartData extends Equatable {
  final DateTime date;
  final int sent;
  final int received;

  const MessageLineChartData({
    required this.date,
    required this.sent,
    required this.received,
  });

  @override
  List<Object?> get props => [date, sent, received];
}

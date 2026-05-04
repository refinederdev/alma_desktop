import 'package:alma_desktop/features/main/domain/entities/message_line_chart_data.dart';

class MessageLineChartDataModel extends MessageLineChartData {
  const MessageLineChartDataModel({
    required super.date,
    required super.sent,
    required super.received,
  }) : super();

  factory MessageLineChartDataModel.fromJson(Map<String, dynamic> json) =>
      MessageLineChartDataModel(
        date: DateTime.parse(json['date'] as String),
        sent: (json['sent'] as num?)?.toInt() ?? 0,
        received: (json['received'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'sent': sent,
    'received': received,
  };
}

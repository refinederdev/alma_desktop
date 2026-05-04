import 'package:alma_desktop/features/main/domain/entities/message_stats.dart';

class MessageStatsModel extends MessageStats {
  const MessageStatsModel({
    required super.totalMessages,
    required super.sent,
    required super.received,
    required super.replyRate,
  }) : super();

  factory MessageStatsModel.fromJson(Map<String, dynamic> json) =>
      MessageStatsModel(
        totalMessages: (json['total_messages'] as num?)?.toInt() ?? 0,
        sent: (json['sent'] as num?)?.toInt() ?? 0,
        received: (json['received'] as num?)?.toInt() ?? 0,
        replyRate: (json['reply_rate'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'total_messages': totalMessages,
    'sent': sent,
    'received': received,
    'reply_rate': replyRate,
  };
}

import 'package:equatable/equatable.dart';

class MessageStats extends Equatable {
  final int totalMessages;
  final int sent;
  final int received;
  final int replyRate;

  const MessageStats({
    required this.totalMessages,
    required this.sent,
    required this.received,
    required this.replyRate,
  });

  @override
  List<Object?> get props => [totalMessages, sent, received, replyRate];
}

import 'package:equatable/equatable.dart';

/// Minimal deal info nested on a message when loading merged customer history.
class MessageDealSummary extends Equatable {
  final int id;
  final String? title;
  final String status;

  const MessageDealSummary({
    required this.id,
    this.title,
    required this.status,
  });

  @override
  List<Object?> get props => [id, title, status];
}

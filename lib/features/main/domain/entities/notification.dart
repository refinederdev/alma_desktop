import 'package:equatable/equatable.dart';

class Notification extends Equatable {
  final String id;
  final String title;
  final String body;
  final String icon;
  final String color;
  final String actionUrl;
  final String actionText;
  final bool isRead;
  final String timeAgo;
  final DateTime createdAt;

  const Notification({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    required this.actionUrl,
    required this.actionText,
    required this.isRead,
    required this.timeAgo,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        icon,
        color,
        actionUrl,
        actionText,
        isRead,
        timeAgo,
        createdAt,
      ];
}

import 'package:alma_desktop/features/main/domain/entities/notification.dart';

class NotificationModel extends Notification {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required super.icon,
    required super.color,
    required super.actionUrl,
    required super.actionText,
    required super.isRead,
    required super.timeAgo,
    required super.createdAt,
  }) : super();

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        icon: json['icon'] as String,
        color: json['color'] as String,
        actionUrl: json['action_url'] as String,
        actionText: json['action_text'] as String,
        isRead: json['is_read'] as bool,
        timeAgo: json['time_ago'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'icon': icon,
    'color': color,
    'action_url': actionUrl,
    'action_text': actionText,
    'is_read': isRead,
    'time_ago': timeAgo,
    'created_at': createdAt.toIso8601String(),
  };
}

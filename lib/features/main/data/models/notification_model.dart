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
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        icon: json['icon']?.toString() ?? 'notifications',
        color: json['color']?.toString() ?? '#006CEA',
        actionUrl: json['action_url']?.toString() ?? '',
        actionText: json['action_text']?.toString() ?? '',
        isRead: json['is_read'] == true,
        timeAgo: json['time_ago']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
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

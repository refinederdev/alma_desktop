import 'package:alma_desktop/features/main/domain/entities/notification_unread_count.dart';

class NotificationUnreadCountModel extends NotificationUnreadCount {
  const NotificationUnreadCountModel({required super.unreadCount}) : super();

  factory NotificationUnreadCountModel.fromJson(Map<String, dynamic> json) =>
      NotificationUnreadCountModel(unreadCount: json['unread_count'] as int);

  Map<String, dynamic> toJson() => {'unread_count': unreadCount};
}

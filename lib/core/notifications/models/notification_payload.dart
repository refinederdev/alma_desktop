import 'package:equatable/equatable.dart';

/// نموذج بيانات الإشعار القادم من FCM
class NotificationPayload extends Equatable {
  final String? notificationId;
  final String? title;
  final String? body;
  final String? imageUrl;
  final NotificationType? type;
  final Map<String, dynamic>? data;
  final String? route;
  final Map<String, dynamic>? routeParams;
  final NotificationPriority? priority;
  final String? sound;
  final int? badge;

  const NotificationPayload({
    this.notificationId,
    this.title,
    this.body,
    this.imageUrl,
    this.type,
    this.data,
    this.route,
    this.routeParams,
    this.priority,
    this.sound,
    this.badge,
  });

  factory NotificationPayload.fromMap(Map<String, dynamic> map) {
    return NotificationPayload(
      notificationId: map['notification_id'] as String? ?? map['id'] as String?,
      title: map['title'] as String?,
      body: map['body'] as String? ?? map['message'] as String?,
      imageUrl: map['image'] as String? ?? map['image_url'] as String?,
      type: map['type'] != null
          ? NotificationType.fromString(map['type'] as String)
          : null,
      data: map['data'] as Map<String, dynamic>? ?? map,
      route: map['route'] as String? ?? map['screen'] as String?,
      routeParams: map['route_params'] as Map<String, dynamic>? ??
          map['params'] as Map<String, dynamic>?,
      priority: map['priority'] != null
          ? NotificationPriority.fromString(map['priority'] as String)
          : NotificationPriority.normal,
      sound: map['sound'] as String?,
      badge: map['badge'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notification_id': notificationId,
      'title': title,
      'body': body,
      'image': imageUrl,
      'type': type?.value,
      'data': data,
      'route': route,
      'route_params': routeParams,
      'priority': priority?.value,
      'sound': sound,
      'badge': badge,
    };
  }

  @override
  List<Object?> get props => [
        notificationId,
        title,
        body,
        imageUrl,
        type,
        data,
        route,
        routeParams,
        priority,
        sound,
        badge,
      ];
}

/// أنواع الإشعارات
enum NotificationType {
  message,
  deal,
  task,
  reminder,
  system,
  announcement,
  other;

  static NotificationType? fromString(String? value) {
    if (value == null) return null;
    try {
      return NotificationType.values.firstWhere(
        (e) => e.name == value.toLowerCase(),
      );
    } catch (_) {
      return NotificationType.other;
    }
  }

  String get value => name;
}

/// أولوية الإشعار
enum NotificationPriority {
  low,
  normal,
  high,
  urgent;

  static NotificationPriority fromString(String? value) {
    if (value == null) return NotificationPriority.normal;
    try {
      return NotificationPriority.values.firstWhere(
        (e) => e.name == value.toLowerCase(),
      );
    } catch (_) {
      return NotificationPriority.normal;
    }
  }

  String get value => name;
}

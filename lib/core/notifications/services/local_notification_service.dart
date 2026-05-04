// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:alma_desktop/core/notifications/models/notification_payload.dart';

// /// خدمة الإشعارات المحلية
// class LocalNotificationService {
//   static final LocalNotificationService _instance =
//       LocalNotificationService._internal();
//   factory LocalNotificationService() => _instance;
//   LocalNotificationService._internal();

//   final FlutterLocalNotificationsPlugin _localNotifications =
//       FlutterLocalNotificationsPlugin();

//   bool _isInitialized = false;

//   /// تهيئة خدمة الإشعارات المحلية
//   Future<void> initialize() async {
//     if (_isInitialized) return;

//     const androidSettings = AndroidInitializationSettings(
//       '@mipmap/ic_launcher',
//     );
//     const iosSettings = DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//       requestCriticalPermission: false,
//     );

//     const initSettings = InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     );

//     await _localNotifications.initialize(
//       settings: initSettings,
//       onDidReceiveNotificationResponse: _onNotificationTapped,
//       onDidReceiveBackgroundNotificationResponse:
//           _onBackgroundNotificationTapped,
//     );

//     // إنشاء قنوات إشعارات للأندرويد
//     await _createNotificationChannels();

//     _isInitialized = true;
//   }

//   /// إنشاء قنوات الإشعارات للأندرويد
//   Future<void> _createNotificationChannels() async {
//     if (Platform.isAndroid) {
//       // قناة عادية
//       const normalChannel = AndroidNotificationChannel(
//         'normal_notifications',
//         'الإشعارات العادية',
//         description: 'إشعارات عامة',
//         importance: Importance.defaultImportance,
//         playSound: true,
//         enableVibration: true,
//       );

//       // قناة عالية الأولوية
//       const highPriorityChannel = AndroidNotificationChannel(
//         'high_priority_notifications',
//         'إشعارات مهمة',
//         description: 'إشعارات عالية الأولوية',
//         importance: Importance.high,
//         playSound: true,
//         enableVibration: true,
//       );

//       // قناة الرسائل
//       const messageChannel = AndroidNotificationChannel(
//         'message_notifications',
//         'إشعارات الرسائل',
//         description: 'إشعارات الرسائل والمحادثات',
//         importance: Importance.high,
//         playSound: true,
//         enableVibration: true,
//       );

//       await _localNotifications
//           .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin
//           >()
//           ?.createNotificationChannel(normalChannel);

//       await _localNotifications
//           .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin
//           >()
//           ?.createNotificationChannel(highPriorityChannel);

//       await _localNotifications
//           .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin
//           >()
//           ?.createNotificationChannel(messageChannel);
//     }
//   }

//   /// معالجة النقر على الإشعار
//   void _onNotificationTapped(NotificationResponse response) {
//     // سيتم التعامل مع هذا في NotificationService
//   }

//   /// معالجة الإشعارات في الخلفية
//   @pragma('vm:entry-point')
//   static void _onBackgroundNotificationTapped(NotificationResponse response) {
//     // سيتم التعامل مع هذا في NotificationService
//   }

//   /// عرض إشعار محلي
//   Future<void> showNotification(NotificationPayload payload) async {
//     if (!_isInitialized) {
//       await initialize();
//     }

//     final androidDetails = _getAndroidDetails(payload);
//     final iosDetails = _getIOSDetails(payload);

//     final notificationDetails = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );

//     final notificationId =
//         (payload.notificationId?.hashCode ??
//                 DateTime.now().millisecondsSinceEpoch)
//             .abs()
//             .clamp(0, 2147483647);

//     await _localNotifications.show(
//       id: notificationId,
//       title: payload.title ?? 'إشعار جديد',
//       body: payload.body ?? '',
//       notificationDetails: notificationDetails,
//       payload: jsonEncode(payload.toMap()),
//     );
//   }

//   /// الحصول على تفاصيل Android للإشعار
//   AndroidNotificationDetails _getAndroidDetails(NotificationPayload payload) {
//     String channelId = 'normal_notifications';
//     Importance importance = Importance.defaultImportance;

//     switch (payload.type) {
//       case NotificationType.message:
//         channelId = 'message_notifications';
//         importance = Importance.high;
//         break;
//       case NotificationType.deal:
//       case NotificationType.task:
//         channelId = 'high_priority_notifications';
//         importance = Importance.high;
//         break;
//       default:
//         break;
//     }

//     switch (payload.priority) {
//       case NotificationPriority.high:
//       case NotificationPriority.urgent:
//         channelId = 'high_priority_notifications';
//         importance = Importance.high;
//         break;
//       default:
//         break;
//     }

//     return AndroidNotificationDetails(
//       channelId,
//       payload.title ?? 'إشعار جديد',
//       channelDescription: payload.body ?? '',
//       importance: importance,
//       priority: _getAndroidPriority(payload.priority),
//       playSound: true,
//       enableVibration: true,
//       icon: '@mipmap/ic_launcher',
//       largeIcon: payload.imageUrl != null
//           ? const DrawableResourceAndroidBitmap('@mipmap/ic_launcher')
//           : null,
//       styleInformation: payload.body != null
//           ? BigTextStyleInformation(payload.body!)
//           : null,
//     );
//   }

//   /// الحصول على أولوية Android
//   Priority _getAndroidPriority(NotificationPriority? priority) {
//     switch (priority) {
//       case NotificationPriority.low:
//         return Priority.low;
//       case NotificationPriority.high:
//         return Priority.high;
//       case NotificationPriority.urgent:
//         return Priority.max;
//       default:
//         return Priority.defaultPriority;
//     }
//   }

//   /// الحصول على تفاصيل iOS للإشعار
//   DarwinNotificationDetails _getIOSDetails(NotificationPayload payload) {
//     return DarwinNotificationDetails(
//       presentAlert: true,
//       presentBadge: true,
//       presentSound: true,
//       sound: payload.sound,
//       badgeNumber: payload.badge,
//       interruptionLevel: _getIOSInterruptionLevel(payload.priority),
//     );
//   }

//   /// الحصول على مستوى المقاطعة لـ iOS
//   InterruptionLevel _getIOSInterruptionLevel(NotificationPriority? priority) {
//     switch (priority) {
//       case NotificationPriority.urgent:
//         return InterruptionLevel.critical;
//       case NotificationPriority.high:
//         return InterruptionLevel.timeSensitive;
//       default:
//         return InterruptionLevel.active;
//     }
//   }

//   /// إلغاء جميع الإشعارات
//   Future<void> cancelAllNotifications() async {
//     await _localNotifications.cancelAll();
//   }

//   /// إلغاء إشعار محدد
//   Future<void> cancelNotification(int id) async {
//     await _localNotifications.cancel(id: id);
//   }

//   /// طلب الأذونات (iOS)
//   Future<bool> requestPermissions() async {
//     if (Platform.isIOS) {
//       final result = await _localNotifications
//           .resolvePlatformSpecificImplementation<
//             IOSFlutterLocalNotificationsPlugin
//           >()
//           ?.requestPermissions(alert: true, badge: true, sound: true);
//       return result ?? false;
//     }
//     return true;
//   }
// }

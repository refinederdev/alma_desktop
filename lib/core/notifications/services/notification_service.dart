// import 'dart:developer';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:get/get.dart';
// import 'package:alma_desktop/core/notifications/models/notification_payload.dart';
// import 'package:alma_desktop/core/notifications/router/notification_router.dart';
// import 'package:alma_desktop/core/notifications/services/local_notification_service.dart';
// import 'package:alma_desktop/core/notifications/services/fcm_token_service.dart';

// /// الخدمة الرئيسية لإدارة الإشعارات
// class NotificationService extends GetxService {
//   final LocalNotificationService _localNotificationService =
//       LocalNotificationService();
//   final FCMTokenService _fcmTokenService = Get.find<FCMTokenService>();
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

//   bool _isInitialized = false;
//   String? _lastForegroundMessageId;
//   DateTime? _lastForegroundMessageTime;
//   static const _dedupeWindow = Duration(seconds: 2);

//   /// تهيئة خدمة الإشعارات
//   Future<void> initialize() async {
//     if (_isInitialized) return;

//     try {
//       // تهيئة الإشعارات المحلية
//       await _localNotificationService.initialize();

//       // طلب الأذونات
//       await _localNotificationService.requestPermissions();

//       // إعداد Firebase Messaging
//       await _setupFirebaseMessaging();

//       _isInitialized = true;
//       log('NotificationService initialized successfully');
//     } catch (e) {
//       log('Error initializing NotificationService: $e');
//     }
//   }

//   /// إعداد Firebase Messaging
//   Future<void> _setupFirebaseMessaging() async {
//     // إعداد خيارات عرض الإشعارات في المقدمة (iOS)
//     await _firebaseMessaging.setForegroundNotificationPresentationOptions(
//       alert: true,
//       badge: true,
//       sound: true,
//     );

//     // معالجة الإشعارات عندما التطبيق في المقدمة
//     FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

//     // معالجة الإشعارات عند فتح التطبيق من إشعار
//     FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

//     // معالجة الإشعارات عند فتح التطبيق من حالة الإنهاء
//     final initialMessage = await _firebaseMessaging.getInitialMessage();
//     if (initialMessage != null) {
//       await _handleMessageOpenedApp(initialMessage);
//     }

//     // معالجة الإشعارات في الخلفية
//     // يتم تسجيلها في firebase_services.dart
//   }

//   /// معالجة الإشعارات في المقدمة
//   Future<void> _handleForegroundMessage(RemoteMessage message) async {
//     log('Foreground message received: ${message.messageId}');

//     // تجنب عرض نفس الإشعار مرتين (أندرويد قد يرسل النسخة مرتين)
//     final now = DateTime.now();
//     if (message.messageId == _lastForegroundMessageId &&
//         _lastForegroundMessageTime != null &&
//         now.difference(_lastForegroundMessageTime!) < _dedupeWindow) {
//       return;
//     }
//     _lastForegroundMessageId = message.messageId;
//     _lastForegroundMessageTime = now;

//     final payload = _parseRemoteMessage(message);

//     // عرض إشعار محلي
//     await _localNotificationService.showNotification(payload);

//     // تحديث عدد الإشعارات غير المقروءة (إذا كان هناك controller)
//     _updateNotificationBadge(payload);
//   }

//   /// معالجة الإشعارات عند فتح التطبيق من إشعار
//   Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
//     log('Message opened app: ${message.messageId}');

//     final payload = _parseRemoteMessage(message);

//     // الانتظار قليلاً للتأكد من تهيئة التطبيق
//     await Future.delayed(const Duration(milliseconds: 500));

//     // توجيه الإشعار
//     await NotificationRouter.route(payload);
//   }

//   /// تحويل RemoteMessage إلى NotificationPayload
//   NotificationPayload _parseRemoteMessage(RemoteMessage message) {
//     final data = message.data;
//     final notification = message.notification;

//     return NotificationPayload(
//       notificationId: message.messageId ?? message.messageId,
//       title: notification?.title ?? data['title'] as String?,
//       body:
//           notification?.body ??
//           data['body'] as String? ??
//           data['message'] as String?,
//       imageUrl:
//           notification?.android?.imageUrl ??
//           notification?.apple?.imageUrl ??
//           data['image'] as String?,
//       type: NotificationType.fromString(data['type'] as String?),
//       data: data,
//       route: data['route'] as String? ?? data['screen'] as String?,
//       routeParams: data['route_params'] != null
//           ? Map<String, dynamic>.from(
//               data['route_params'] as Map<String, dynamic>,
//             )
//           : data['params'] != null
//           ? Map<String, dynamic>.from(data['params'] as Map<String, dynamic>)
//           : null,
//       priority: NotificationPriority.fromString(data['priority'] as String?),
//       sound: notification?.android?.sound,
//       badge: notification?.apple?.badge != null
//           ? int.tryParse(notification?.apple?.badge ?? '')
//           : null,
//     );
//   }

//   /// تحديث شارة الإشعارات
//   void _updateNotificationBadge(NotificationPayload payload) {
//     // يمكنك إضافة منطق لتحديث عدد الإشعارات غير المقروءة
//     // مثال: Get.find<NotificationsController>().getNotificationsUnreadCount();
//   }

//   /// الحصول على FCM Token
//   Future<String?> getFCMToken() async {
//     return await _fcmTokenService.initialize();
//   }

//   /// الاشتراك في topic
//   Future<void> subscribeToTopic(String topic) async {
//     await _fcmTokenService.subscribeToTopic(topic);
//   }

//   /// إلغاء الاشتراك من topic
//   Future<void> unsubscribeFromTopic(String topic) async {
//     await _fcmTokenService.unsubscribeFromTopic(topic);
//   }

//   /// عرض إشعار محلي مخصص
//   Future<void> showLocalNotification(NotificationPayload payload) async {
//     await _localNotificationService.showNotification(payload);
//   }

//   /// إلغاء جميع الإشعارات
//   Future<void> cancelAllNotifications() async {
//     await _localNotificationService.cancelAllNotifications();
//   }
// }

// /// معالج الإشعارات في الخلفية
// /// يجب أن يكون top-level function
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   log('Background message received: ${message.messageId}');

//   // تهيئة Firebase و GetX
//   // سيتم استدعاء هذا من main.dart أو من ملف منفصل
//   // await Firebase.initializeApp();
//   // await InjectorContainer.init();

//   // يمكنك حفظ الإشعار في قاعدة البيانات المحلية هنا
//   // أو إرساله إلى الخادم
// }

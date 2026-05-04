// import 'package:get/get.dart';
// import 'package:alma_desktop/core/notifications/models/notification_payload.dart';
// import 'package:alma_desktop/core/notifications/services/notification_service.dart';
// import 'package:alma_desktop/core/notifications/services/fcm_token_service.dart';

// /// مساعد سهل الاستخدام لنظام الإشعارات
// class NotificationHelper {
//   /// الحصول على NotificationService
//   static NotificationService get _service => Get.find<NotificationService>();

//   /// الحصول على FCMTokenService
//   static FCMTokenService get _tokenService => Get.find<FCMTokenService>();

//   /// الحصول على FCM Token
//   static Future<String?> getFCMToken() async {
//     return await _tokenService.currentToken ?? await _tokenService.initialize();
//   }

//   /// عرض إشعار محلي مخصص
//   static Future<void> showLocalNotification({
//     String? title,
//     String? body,
//     String? imageUrl,
//     NotificationType? type,
//     Map<String, dynamic>? data,
//     String? route,
//     Map<String, dynamic>? routeParams,
//     NotificationPriority? priority,
//   }) async {
//     final payload = NotificationPayload(
//       title: title,
//       body: body,
//       imageUrl: imageUrl,
//       type: type,
//       data: data,
//       route: route,
//       routeParams: routeParams,
//       priority: priority,
//     );

//     await _service.showLocalNotification(payload);
//   }

//   /// الاشتراك في topic
//   static Future<void> subscribeToTopic(String topic) async {
//     await _service.subscribeToTopic(topic);
//   }

//   /// إلغاء الاشتراك من topic
//   static Future<void> unsubscribeFromTopic(String topic) async {
//     await _service.unsubscribeFromTopic(topic);
//   }

//   /// إلغاء جميع الإشعارات
//   static Future<void> cancelAllNotifications() async {
//     await _service.cancelAllNotifications();
//   }

//   /// مثال: إرسال إشعار رسالة
//   static Future<void> showMessageNotification({
//     required String chatId,
//     required String senderName,
//     required String message,
//   }) async {
//     await showLocalNotification(
//       title: senderName,
//       body: message,
//       type: NotificationType.message,
//       data: {'chat_id': chatId},
//       route: '/chat_details',
//       routeParams: {'dealId': chatId},
//       priority: NotificationPriority.high,
//     );
//   }

//   /// مثال: إرسال إشعار صفقة
//   static Future<void> showDealNotification({
//     required String dealId,
//     required String title,
//     required String body,
//   }) async {
//     await showLocalNotification(
//       title: title,
//       body: body,
//       type: NotificationType.deal,
//       data: {'deal_id': dealId},
//       route: '/chat_details',
//       routeParams: {'dealId': dealId},
//       priority: NotificationPriority.high,
//     );
//   }

//   /// مثال: إرسال إشعار نظامي
//   static Future<void> showSystemNotification({
//     required String title,
//     required String body,
//   }) async {
//     await showLocalNotification(
//       title: title,
//       body: body,
//       type: NotificationType.system,
//       priority: NotificationPriority.normal,
//     );
//   }
// }

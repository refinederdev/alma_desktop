// /// أمثلة على استخدام نظام الإشعارات
// ///
// /// هذا الملف يحتوي على أمثلة عملية لكيفية استخدام نظام الإشعارات

// import 'package:alma_desktop/core/notifications/notification_helper.dart';
// import 'package:alma_desktop/core/notifications/models/notification_payload.dart';

// class NotificationExamples {
//   /// مثال 1: إشعار بسيط
//   static Future<void> simpleNotification() async {
//     await NotificationHelper.showLocalNotification(
//       title: 'مرحباً',
//       body: 'هذا إشعار بسيط',
//     );
//   }

//   /// مثال 2: إشعار رسالة مع توجيه
//   static Future<void> messageNotification() async {
//     await NotificationHelper.showMessageNotification(
//       chatId: '123',
//       senderName: 'أحمد محمد',
//       message: 'مرحباً، كيف حالك؟',
//     );
//   }

//   /// مثال 3: إشعار صفقة
//   static Future<void> dealNotification() async {
//     await NotificationHelper.showDealNotification(
//       dealId: '456',
//       title: 'صفقة جديدة',
//       body: 'تم إنشاء صفقة جديدة تحتاج إلى مراجعتك',
//     );
//   }

//   /// مثال 4: إشعار عاجل
//   static Future<void> urgentNotification() async {
//     await NotificationHelper.showLocalNotification(
//       title: 'تنبيه عاجل',
//       body: 'هذا إشعار عاجل يحتاج إلى انتباهك',
//       priority: NotificationPriority.urgent,
//     );
//   }

//   /// مثال 5: إشعار مع صورة
//   static Future<void> notificationWithImage() async {
//     await NotificationHelper.showLocalNotification(
//       title: 'إشعار مع صورة',
//       body: 'هذا إشعار يحتوي على صورة',
//       imageUrl: 'https://example.com/image.jpg',
//     );
//   }

//   /// مثال 6: إشعار مخصص مع بيانات إضافية
//   static Future<void> customNotification() async {
//     await NotificationHelper.showLocalNotification(
//       title: 'إشعار مخصص',
//       body: 'هذا إشعار يحتوي على بيانات مخصصة',
//       type: NotificationType.task,
//       data: {
//         'task_id': '789',
//         'due_date': '2026-01-30',
//         'priority': 'high',
//       },
//       route: '/tasks',
//       routeParams: {'taskId': '789'},
//       priority: NotificationPriority.high,
//     );
//   }

//   /// مثال 7: الاشتراك في topics
//   static Future<void> subscribeToTopics() async {
//     // الاشتراك في إشعارات الجميع
//     await NotificationHelper.subscribeToTopic('all');

//     // الاشتراك في إشعارات العملاء
//     await NotificationHelper.subscribeToTopic('clients');

//     // الاشتراك في إشعارات المبيعات
//     await NotificationHelper.subscribeToTopic('sales');
//   }

//   /// مثال 8: الحصول على FCM Token
//   static Future<void> getFCMTokenExample() async {
//     final token = await NotificationHelper.getFCMToken();
//     if (token != null) {
//       print('FCM Token: $token');
//       // أرسل الـ token للخادم
//       // await apiService.updateFCMToken(token);
//     } else {
//       print('فشل الحصول على FCM Token');
//     }
//   }

//   /// مثال 9: إشعار تذكير
//   static Future<void> reminderNotification() async {
//     await NotificationHelper.showLocalNotification(
//       title: 'تذكير',
//       body: 'لا تنسى الاجتماع الساعة 3 مساءً',
//       type: NotificationType.reminder,
//       priority: NotificationPriority.normal,
//     );
//   }

//   /// مثال 10: إشعار إعلان
//   static Future<void> announcementNotification() async {
//     await NotificationHelper.showLocalNotification(
//       title: 'إعلان مهم',
//       body: 'تحديث جديد متاح للتطبيق',
//       type: NotificationType.announcement,
//       priority: NotificationPriority.high,
//     );
//   }
// }

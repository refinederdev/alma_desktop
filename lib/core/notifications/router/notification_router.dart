// import 'package:get/get.dart';
// import 'package:alma_desktop/core/config/app_routes.dart';
// import 'package:alma_desktop/core/notifications/models/notification_payload.dart';

// /// نظام توجيه الإشعارات الذكي
// class NotificationRouter {
//   /// توجيه الإشعار بناءً على البيانات
//   static Future<void> route(NotificationPayload payload) async {
//     try {
//       // إذا كان هناك route محدد في payload
//       if (payload.route != null) {
//         await _navigateToRoute(payload.route!, payload.routeParams ?? {});
//         return;
//       }

//       // التوجيه بناءً على نوع الإشعار
//       switch (payload.type) {
//         case NotificationType.message:
//           await _handleMessageNotification(payload);
//           break;
//         case NotificationType.deal:
//           await _handleDealNotification(payload);
//           break;
//         case NotificationType.task:
//           await _handleTaskNotification(payload);
//           break;
//         case NotificationType.reminder:
//           await _handleReminderNotification(payload);
//           break;
//         case NotificationType.system:
//           await _handleSystemNotification(payload);
//           break;
//         case NotificationType.announcement:
//           await _handleAnnouncementNotification(payload);
//           break;
//         case NotificationType.other:
//         case null:
//           await _handleDefaultNotification(payload);
//           break;
//       }
//     } catch (e) {
//       // في حالة الخطأ، نفتح صفحة الإشعارات العامة
//       Get.toNamed(AppRoutes.notifications);
//     }
//   }

//   /// معالجة إشعارات الرسائل
//   static Future<void> _handleMessageNotification(
//     NotificationPayload payload,
//   ) async {
//     final chatId =
//         payload.data?['chat_id'] as String? ??
//         payload.data?['deal_id'] as String?;
//     if (chatId != null) {
//       Get.toNamed(AppRoutes.chatDetails, arguments: {'dealId': chatId});
//     } else {
//       Get.toNamed(AppRoutes.notifications);
//     }
//   }

//   /// معالجة إشعارات الصفقات
//   static Future<void> _handleDealNotification(
//     NotificationPayload payload,
//   ) async {
//     final dealId =
//         payload.data?['deal_id'] as String? ?? payload.data?['id'] as String?;
//     if (dealId != null) {
//       Get.toNamed(AppRoutes.chatDetails, arguments: {'dealId': dealId});
//     } else {
//       Get.toNamed(AppRoutes.notifications);
//     }
//   }

//   /// معالجة إشعارات المهام
//   static Future<void> _handleTaskNotification(
//     NotificationPayload payload,
//   ) async {
//     final taskId = payload.data?['task_id'] as String?;
//     if (taskId != null) {
//       // يمكن إضافة route للمهام لاحقاً
//       Get.toNamed(AppRoutes.notifications);
//     } else {
//       Get.toNamed(AppRoutes.notifications);
//     }
//   }

//   /// معالجة التذكيرات
//   static Future<void> _handleReminderNotification(
//     NotificationPayload payload,
//   ) async {
//     Get.toNamed(AppRoutes.notifications);
//   }

//   /// معالجة الإشعارات النظامية
//   static Future<void> _handleSystemNotification(
//     NotificationPayload payload,
//   ) async {
//     Get.toNamed(AppRoutes.notifications);
//   }

//   /// معالجة الإعلانات
//   static Future<void> _handleAnnouncementNotification(
//     NotificationPayload payload,
//   ) async {
//     Get.toNamed(AppRoutes.notifications);
//   }

//   /// معالجة الإشعارات الافتراضية
//   static Future<void> _handleDefaultNotification(
//     NotificationPayload payload,
//   ) async {
//     Get.toNamed(AppRoutes.notifications);
//   }

//   /// التنقل إلى route معين
//   static Future<void> _navigateToRoute(
//     String route,
//     Map<String, dynamic> params,
//   ) async {
//     // التحقق من وجود الـ route
//     if (Get.isRegistered<GetPage>(tag: route) || Get.routing.current == route) {
//       Get.toNamed(
//         route,
//         parameters: params.map((key, value) => MapEntry(key, value.toString())),
//       );
//     } else {
//       // محاولة استخدام route مباشرة
//       try {
//         Get.toNamed(
//           route,
//           parameters: params.map(
//             (key, value) => MapEntry(key, value.toString()),
//           ),
//         );
//       } catch (_) {
//         // في حالة الفشل، نفتح صفحة الإشعارات
//         Get.toNamed(AppRoutes.notifications);
//       }
//     }
//   }
// }

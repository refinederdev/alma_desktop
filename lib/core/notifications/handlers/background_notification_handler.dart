// import 'dart:developer';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:alma_desktop/firebase_options.dart';
// import 'package:alma_desktop/core/config/injector_container.dart';

// /// معالج الإشعارات في الخلفية
// /// يجب أن يكون top-level function مع @pragma('vm:entry-point')
// @pragma('vm:entry-point')
// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   log('Background message received: ${message.messageId}');
//   log('Message data: ${message.data}');
//   log('Message notification: ${message.notification?.title}');

//   try {
//     // تهيئة Firebase إذا لم يكن مهيأ
//     try {
//       await Firebase.initializeApp(
//         options: DefaultFirebaseOptions.currentPlatform,
//       );
//     } catch (_) {
//       // Firebase قد يكون مهيأ بالفعل
//     }

//     // تهيئة InjectorContainer
//     try {
//       await InjectorContainer.init();
//     } catch (_) {
//       // قد يكون مهيأ بالفعل
//     }

//     // هنا يمكنك:
//     // 1. حفظ الإشعار في قاعدة البيانات المحلية
//     // 2. تحديث عدد الإشعارات غير المقروءة
//     // 3. إرسال الإشعار للخادم
//     // 4. أي منطق آخر مطلوب

//     // مثال: حفظ الإشعار
//     // final notification = NotificationPayload.fromMap(message.data);
//     // await NotificationRepository.saveNotification(notification);

//   } catch (e) {
//     log('Error handling background message: $e');
//   }
// }

// import 'dart:developer';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:get/get.dart';
// import 'package:alma_desktop/firebase_options.dart';
// import 'package:alma_desktop/core/notifications/services/notification_service.dart';
// import 'package:alma_desktop/core/notifications/services/fcm_token_service.dart';
// import 'package:alma_desktop/core/services/local_storage_service/local_storage_service.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:alma_desktop/core/notifications/handlers/background_notification_handler.dart';

// class FirebaseServices extends Bindings {
//   @override
//   Future<void> dependencies() async {
//     try {
//       // تهيئة Firebase
//       await Firebase.initializeApp(
//         options: DefaultFirebaseOptions.currentPlatform,
//       );

//       // تسجيل معالج الإشعارات في الخلفية
//       FirebaseMessaging.onBackgroundMessage(
//         firebaseMessagingBackgroundHandler,
//       );

//       // تسجيل FCM Token Service
//       Get.put<FCMTokenService>(
//         FCMTokenService(Get.find<LocalStorageService>()),
//         permanent: true,
//       );

//       // تهيئة FCM Token Service
//       final fcmTokenService = Get.find<FCMTokenService>();
//       await fcmTokenService.initialize();

//       // تسجيل Notification Service
//       Get.put<NotificationService>(
//         NotificationService(),
//         permanent: true,
//       );

//       // تهيئة Notification Service
//       final notificationService = Get.find<NotificationService>();
//       await notificationService.initialize();

//       log('Firebase Services initialized successfully');
//     } catch (e) {
//       log('Error initializing Firebase Services: $e');
//     }
//   }
// }

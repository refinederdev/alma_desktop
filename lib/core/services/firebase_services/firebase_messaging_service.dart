// import 'dart:convert';
// import 'dart:developer';

// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:get/get.dart';
// import 'package:alma_desktop/core/services/firebase_services/firebase_background_notification_injector.dart';
// import 'package:alma_desktop/core/services/firebase_services/firebase_services.dart';
// import 'package:alma_desktop/core/services/firebase_services/notification_control.dart';
// import 'package:alma_desktop/core/services/local_storage_service/local_storage_service.dart';

// class FirebaseMessagingService extends GetxService {
//   String? token;

//   @override
//   Future<void> onInit() async {
//     super.onInit();
//   }

//   // Firebase Messaging Services Initilization
//   Future<void> firebaseMessagingServiceInit() async {
//     await FirebaseMessaging.instance
//         .setForegroundNotificationPresentationOptions(
//           alert: true,
//           badge: true,
//           sound: true,
//         );

//     FirebaseMessaging.instance.getInitialMessage().then((message) async {
//       log('getInitialMessage');
//     });

//     FirebaseMessaging.onMessage.listen((message) async {
//       log('onMessage');
//       final notificationsCtrl = Get.find<NotificationControl>();
//       log(message.data.toString());

//       notificationsCtrl.showNotification(message: message);
//     });

//     FirebaseMessaging.onMessageOpenedApp.listen((message) async {
//       log('onMessageOpenedApp');
//       final notificationsCtrl = Get.find<NotificationControl>();
//       notificationsCtrl.showNotification(message: message);
//     });

//     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

//     FirebaseMessaging.instance.subscribeToTopic('all');
//     FirebaseMessaging.instance.subscribeToTopic('client');
//     token = await FirebaseMessaging.instance.getToken();
//     log(token.toString());
//   }
// }

// // here when app is closed completely and a message is trigger  this function will be called
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   // Save The Remote Message as Json in the prefrences
//   await FirebaseServices().dependencies();
//   await FirebaseBackgroundNotificationInjector().init();
//   var localStorage = Get.find<LocalStorageService>();
//   localStorage.setString("notification", jsonEncode(message.toMap()));
//   // Get.find<NotificationControl>().showNotification(message: message);
// }

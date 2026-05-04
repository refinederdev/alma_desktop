// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:get/get.dart';
// import 'package:alma_desktop/core/helpers/app_dialogs_helper.dart';
// // import 'package:alma_desktop/core/config/app_routes.dart';
// // import 'package:alma_desktop/core/config/notification_actions.dart';
// // import 'package:nour/core/utils/helpers/app_dialogs.dart';
// // import 'package:url_launcher/url_launcher_string.dart';

// class NotificationControl {
//   notificationsInit() {}

//   void showNotification({required RemoteMessage message}) async {
//     Get.dialog(
//       AppDialogsHelper.show(
//         title: message.notification?.title,
//         message: message.notification?.body,
//         image: "Phone.svg",
//         onPressed: () {
//           Get.back();
//           exexuteAction(message.data);
//         },
//       ),
//     );
//   }

//   void notificationRouting(NotificationRouteData data) {}

//   void exexuteAction(Map<String, dynamic> data) async {
//     if (data.isNotEmpty) {}
//   }
// }

// class NotificationRouteData {
//   final String pageName;
//   final String? id;

//   const NotificationRouteData({required this.pageName, this.id});

//   factory NotificationRouteData.fromJson(Map<String, dynamic> json) {
//     return NotificationRouteData(pageName: json["pageName"], id: json["id"]);
//   }
// }

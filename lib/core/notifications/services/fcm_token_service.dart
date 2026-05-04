// import 'dart:developer';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:get/get.dart';
// import 'package:alma_desktop/core/services/local_storage_service/local_storage_service.dart';

// /// خدمة إدارة FCM Token
// class FCMTokenService extends GetxService {
//   final LocalStorageService _localStorage;
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

//   FCMTokenService(this._localStorage);

//   String? _currentToken;
//   static const String _tokenKey = 'fcm_token';

//   /// الحصول على الـ token الحالي
//   String? get currentToken => _currentToken;

//   /// تهيئة الخدمة والحصول على الـ token
//   Future<String?> initialize() async {
//     try {
//       // الحصول على الـ token المحفوظ
//       _currentToken = _localStorage.getString(_tokenKey);

//       // طلب الأذونات
//       await _requestPermissions();

//       // الحصول على الـ token الجديد
//       final token = await _firebaseMessaging.getToken();
//       if (token != null) {
//         _currentToken = token;
//         await _localStorage.setString(_tokenKey, token);
//         log('FCM Token: $token');
//       }

//       // الاستماع لتغييرات الـ token
//       _firebaseMessaging.onTokenRefresh.listen((newToken) async {
//         _currentToken = newToken;
//         await _localStorage.setString(_tokenKey, newToken);
//         log('FCM Token Refreshed: $newToken');
//         await _onTokenRefreshed(newToken);
//       });

//       return _currentToken;
//     } catch (e) {
//       log('Error getting FCM token: $e');
//       return null;
//     }
//   }

//   /// طلب أذونات الإشعارات
//   Future<void> _requestPermissions() async {
//     final settings = await _firebaseMessaging.requestPermission(
//       alert: true,
//       announcement: false,
//       badge: true,
//       carPlay: false,
//       criticalAlert: false,
//       provisional: false,
//       sound: true,
//     );

//     log('Notification permission status: ${settings.authorizationStatus}');
//   }

//   /// معالجة تحديث الـ token
//   Future<void> _onTokenRefreshed(String newToken) async {
//     // هنا يمكنك إرسال الـ token الجديد للخادم
//     // مثال: await apiService.updateFCMToken(newToken);
//   }

//   /// الاشتراك في topic
//   Future<void> subscribeToTopic(String topic) async {
//     try {
//       await _firebaseMessaging.subscribeToTopic(topic);
//       log('Subscribed to topic: $topic');
//     } catch (e) {
//       log('Error subscribing to topic $topic: $e');
//     }
//   }

//   /// إلغاء الاشتراك من topic
//   Future<void> unsubscribeFromTopic(String topic) async {
//     try {
//       await _firebaseMessaging.unsubscribeFromTopic(topic);
//       log('Unsubscribed from topic: $topic');
//     } catch (e) {
//       log('Error unsubscribing from topic $topic: $e');
//     }
//   }

//   /// حذف الـ token
//   Future<void> deleteToken() async {
//     try {
//       await _firebaseMessaging.deleteToken();
//       _currentToken = null;
//       _localStorage.remove(_tokenKey);
//       log('FCM Token deleted');
//     } catch (e) {
//       log('Error deleting FCM token: $e');
//     }
//   }
// }

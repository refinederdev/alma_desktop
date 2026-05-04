# نظام الإشعارات المتقدم 🔔

نظام إشعارات شامل ومجرد يعمل على iOS و Android باستخدام Firebase Cloud Messaging (FCM).

## المميزات ✨

- ✅ دعم كامل لـ iOS و Android
- ✅ معالجة جميع حالات الإشعارات (Foreground, Background, Terminated)
- ✅ نظام توجيه ذكي للإشعارات
- ✅ إدارة FCM Token تلقائية
- ✅ دعم الإشعارات المحلية
- ✅ قنوات إشعارات متعددة للأندرويد
- ✅ دعم الأولويات المختلفة
- ✅ واجهة برمجية سهلة الاستخدام

## البنية 📁

```
lib/core/notifications/
├── models/
│   └── notification_payload.dart      # نموذج بيانات الإشعار
├── router/
│   └── notification_router.dart       # نظام التوجيه الذكي
├── services/
│   ├── notification_service.dart      # الخدمة الرئيسية
│   ├── local_notification_service.dart # خدمة الإشعارات المحلية
│   └── fcm_token_service.dart         # خدمة إدارة FCM Token
├── handlers/
│   └── background_notification_handler.dart # معالج الخلفية
├── notification_helper.dart           # مساعد سهل الاستخدام
└── README.md                          # هذا الملف
```

## الاستخدام السريع 🚀

### 1. الحصول على FCM Token

```dart
import 'package:alma_desktop/core/notifications/notification_helper.dart';

// الحصول على Token
final token = await NotificationHelper.getFCMToken();
print('FCM Token: $token');
```

### 2. عرض إشعار محلي

```dart
// إشعار بسيط
await NotificationHelper.showLocalNotification(
  title: 'عنوان الإشعار',
  body: 'محتوى الإشعار',
);

// إشعار مع توجيه
await NotificationHelper.showLocalNotification(
  title: 'رسالة جديدة',
  body: 'لديك رسالة من أحمد',
  type: NotificationType.message,
  route: '/chat_details',
  routeParams: {'dealId': '123'},
  priority: NotificationPriority.high,
);
```

### 3. استخدام الدوال المساعدة

```dart
// إشعار رسالة
await NotificationHelper.showMessageNotification(
  chatId: '123',
  senderName: 'أحمد',
  message: 'مرحباً!',
);

// إشعار صفقة
await NotificationHelper.showDealNotification(
  dealId: '456',
  title: 'صفقة جديدة',
  body: 'تم إنشاء صفقة جديدة',
);

// إشعار نظامي
await NotificationHelper.showSystemNotification(
  title: 'تحديث',
  body: 'تم تحديث التطبيق',
);
```

### 4. الاشتراك في Topics

```dart
// الاشتراك
await NotificationHelper.subscribeToTopic('all');
await NotificationHelper.subscribeToTopic('client');

// إلغاء الاشتراك
await NotificationHelper.unsubscribeFromTopic('client');
```

## تنسيق الإشعارات من الخادم 📨

### تنسيق JSON للإشعارات

```json
{
  "notification": {
    "title": "عنوان الإشعار",
    "body": "محتوى الإشعار",
    "sound": "default"
  },
  "data": {
    "type": "message",
    "route": "/chat_details",
    "route_params": {
      "dealId": "123"
    },
    "priority": "high",
    "chat_id": "123"
  },
  "topic": "all"
}
```

### أنواع الإشعارات المدعومة

- `message` - إشعارات الرسائل
- `deal` - إشعارات الصفقات
- `task` - إشعارات المهام
- `reminder` - التذكيرات
- `system` - إشعارات النظام
- `announcement` - الإعلانات
- `other` - أخرى

### الأولويات

- `low` - منخفضة
- `normal` - عادية (افتراضي)
- `high` - عالية
- `urgent` - عاجلة

## الإعدادات المطلوبة ⚙️

### Android

تم إضافة الأذونات التالية في `AndroidManifest.xml`:
- `POST_NOTIFICATIONS`
- `VIBRATE`
- `RECEIVE_BOOT_COMPLETED`

### iOS

تم إضافة `UIBackgroundModes` في `Info.plist`:
- `remote-notification`
- `fetch`

**ملاحظة مهمة:** يجب تفعيل Push Notifications في Xcode:
1. افتح `ios/Runner.xcworkspace`
2. اختر Runner في Project Navigator
3. اذهب إلى Signing & Capabilities
4. أضف Push Notifications capability
5. أضف Background Modes واختر Remote notifications

## التكامل مع النظام الحالي 🔗

النظام متكامل تلقائياً مع:
- ✅ `FirebaseServices` - يتم تهيئته تلقائياً
- ✅ `InjectorContainer` - يتم تسجيله تلقائياً
- ✅ `NotificationRouter` - يتكامل مع `AppRoutes`

## أمثلة متقدمة 💡

### معالجة الإشعارات المخصصة

```dart
import 'package:alma_desktop/core/notifications/services/notification_service.dart';

final notificationService = Get.find<NotificationService>();

// عرض إشعار مخصص
await notificationService.showLocalNotification(
  NotificationPayload(
    title: 'عنوان',
    body: 'محتوى',
    type: NotificationType.message,
    priority: NotificationPriority.high,
  ),
);
```

### تحديث عدد الإشعارات غير المقروءة

```dart
// في NotificationService._updateNotificationBadge
// يمكنك إضافة:
Get.find<NotificationsController>().getNotificationsUnreadCount();
```

## استكشاف الأخطاء 🐛

### الإشعارات لا تظهر على iOS

1. تأكد من تفعيل Push Notifications في Xcode
2. تأكد من رفع APNs Key في Firebase Console
3. تأكد من طلب الأذونات من المستخدم

### الإشعارات لا تظهر على Android

1. تأكد من طلب أذونات `POST_NOTIFICATIONS` على Android 13+
2. تأكد من إعداد قنوات الإشعارات
3. تحقق من إعدادات الإشعارات في إعدادات الجهاز

### Token لا يتم الحصول عليه

```dart
// تحقق من تهيئة Firebase
final token = await NotificationHelper.getFCMToken();
if (token == null) {
  print('فشل الحصول على Token');
}
```

## الدعم 📞

للمزيد من المعلومات، راجع:
- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)

---

**تم التطوير بواسطة:** نظام الإشعارات المتقدم 🔔

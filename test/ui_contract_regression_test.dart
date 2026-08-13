import 'package:alma_desktop/core/lang/ar.dart';
import 'package:alma_desktop/core/lang/en.dart';
import 'package:alma_desktop/features/calls/data/models/whatsapp_call_model.dart';
import 'package:alma_desktop/features/main/data/models/notification_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('desktop UI data contracts', () {
    test('Arabic and English expose the same localization keys', () {
      final arabicOnly = ArLang.keys.keys.toSet().difference(
        EnLang.keys.keys.toSet(),
      );
      final englishOnly = EnLang.keys.keys.toSet().difference(
        ArLang.keys.keys.toSet(),
      );

      expect(arabicOnly, isEmpty);
      expect(englishOnly, isEmpty);
    });

    test('nullable notification presentation fields never crash parsing', () {
      final notification = NotificationModel.fromJson({
        'id': 'notice-1',
        'title': 'A title',
        'body': 'A body',
        'icon': null,
        'color': null,
        'action_url': null,
        'action_text': null,
        'is_read': false,
        'time_ago': null,
        'created_at': '2026-08-13T09:00:00Z',
      });

      expect(notification.icon, 'notifications');
      expect(notification.actionUrl, isEmpty);
      expect(notification.actionText, isEmpty);
    });

    test(
      'call history accepts backend formatted duration and nested contact',
      () {
        final call = WhatsAppCallModel.fromJson({
          'id': 7,
          'direction': 'inbound',
          'status': 'completed',
          'formatted_duration': '03:21',
          'deal': {'contact_name': 'Maya'},
        });

        expect(call.duration, '03:21');
        expect(call.contactName, 'Maya');
      },
    );
  });
}

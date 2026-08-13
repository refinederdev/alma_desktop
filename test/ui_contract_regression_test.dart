import 'dart:io';

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

    test('presentation code contains no raw user-facing string literals', () {
      final roots = [
        Directory('lib/features'),
        Directory('lib/core/widgets'),
        Directory('lib/core/errors'),
      ];
      final visibleLiteral = RegExp(
        r'''(?:Text\(\s*|tooltip\s*:\s*|hintText\s*:\s*|labelText\s*:\s*|semanticLabel\s*:\s*|message\s*:\s*)['"]([^'"]*)['"]''',
        multiLine: true,
      );
      final numericOrTemplate = RegExp(r'^[\d+Xx .:/#-]*$');
      final offenders = <String>[];

      for (final root in roots) {
        for (final entity in root.listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          final source = entity.readAsStringSync();
          for (final match in visibleLiteral.allMatches(source)) {
            final literal = match.group(1) ?? '';
            final suffix = source.substring(
              match.end,
              (match.end + 32).clamp(0, source.length),
            );
            if (literal.isEmpty ||
                literal.contains(r'$') ||
                numericOrTemplate.hasMatch(literal) ||
                suffix.contains('.tr')) {
              continue;
            }
            final line =
                '\n'.allMatches(source.substring(0, match.start)).length + 1;
            offenders.add('${entity.path}:$line: $literal');
          }
        }
      }

      expect(offenders, isEmpty, reason: offenders.join('\n'));
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

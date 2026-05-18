import 'package:alma_desktop/features/calls/domain/entities/call_permission.dart';

class CallPermissionModel extends CallPermission {
  const CallPermissionModel({
    required super.granted,
    super.state,
    super.expiresAt,
    super.requestedAt,
    super.raw,
  });

  factory CallPermissionModel.fromJson(Map<String, dynamic> json) {
    bool truthy(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.toLowerCase().trim();
        return s == 'granted' || s == 'true' || s == '1' || s == 'allowed';
      }
      return false;
    }

    DateTime? parseDate(dynamic v) {
      if (v is String && v.isNotEmpty) {
        try {
          return DateTime.parse(v).toUtc().toLocal();
        } catch (_) {
          return null;
        }
      }
      if (v is num) {
        return DateTime.fromMillisecondsSinceEpoch(v.toInt() * 1000);
      }
      return null;
    }

    // الميتا قد تأتي تحت مفاتيح متعددة بحسب استجابة Meta
    final state = (json['permission'] as String?) ??
        (json['state'] as String?) ??
        (json['status'] as String?);
    final granted = json['granted'] is bool
        ? json['granted'] as bool
        : truthy(state);

    return CallPermissionModel(
      granted: granted,
      state: state,
      expiresAt: parseDate(json['expires_at']) ?? parseDate(json['expiry']),
      requestedAt:
          parseDate(json['requested_at']) ?? parseDate(json['updated_at']),
      raw: Map<String, dynamic>.from(json),
    );
  }
}

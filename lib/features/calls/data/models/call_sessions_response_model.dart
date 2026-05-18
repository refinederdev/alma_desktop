import 'package:alma_desktop/features/calls/data/models/call_session_model.dart';
import 'package:alma_desktop/features/calls/data/models/ice_server_model.dart';
import 'package:alma_desktop/features/calls/domain/entities/call_sessions_response.dart';

class CallSessionsResponseModel extends CallSessionsResponse {
  const CallSessionsResponseModel({
    required super.sessions,
    required super.iceServers,
  });

  factory CallSessionsResponseModel.fromJson(Map<String, dynamic> json) {
    final sessionsRaw = json['sessions'] as List<dynamic>? ?? const [];
    final iceRaw = json['ice_servers'] as List<dynamic>? ?? const [];

    final sessions = sessionsRaw
        .whereType<Map>()
        .map(
          (e) => CallSessionModel.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();

    final iceServers = iceRaw
        .whereType<Map>()
        .map(
          (e) => IceServerModel.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();

    return CallSessionsResponseModel(
      sessions: sessions,
      iceServers: iceServers,
    );
  }
}

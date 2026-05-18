import 'package:alma_desktop/features/calls/domain/entities/call_session.dart';
import 'package:alma_desktop/features/calls/domain/entities/ice_server.dart';
import 'package:equatable/equatable.dart';

class CallSessionsResponse extends Equatable {
  final List<CallSession> sessions;
  final List<IceServer> iceServers;

  const CallSessionsResponse({
    required this.sessions,
    required this.iceServers,
  });

  @override
  List<Object?> get props => [sessions, iceServers];
}

import 'package:alma_desktop/features/calls/domain/entities/whatsapp_call.dart';
import 'package:equatable/equatable.dart';

/// أنواع الأحداث القادمة عبر `private-calls.{sessionId}` بالاسم `.call.event`.
enum CallEventType {
  incomingCall,
  callConnected,
  callRinging,
  callAccepted,
  callRejected,
  callTerminated,
  unknown;

  static CallEventType fromString(String? value) {
    switch (value) {
      case 'incoming_call':
        return CallEventType.incomingCall;
      case 'call_connected':
        return CallEventType.callConnected;
      case 'call_ringing':
        return CallEventType.callRinging;
      case 'call_accepted':
        return CallEventType.callAccepted;
      case 'call_rejected':
        return CallEventType.callRejected;
      case 'call_terminated':
        return CallEventType.callTerminated;
      default:
        return CallEventType.unknown;
    }
  }
}

class CallEvent extends Equatable {
  final CallEventType type;
  final WhatsAppCall? call;
  final int? sessionId;
  final DateTime? timestamp;
  final String rawType;

  const CallEvent({
    required this.type,
    required this.rawType,
    this.call,
    this.sessionId,
    this.timestamp,
  });

  @override
  List<Object?> get props => [type, rawType, call, sessionId, timestamp];
}

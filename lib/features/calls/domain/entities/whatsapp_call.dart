import 'package:equatable/equatable.dart';

/// تمثيل مكالمة واتساب من واجهة `WhatsAppCallResource`.
class WhatsAppCall extends Equatable {
  final int id;
  final String? callId;
  final String direction; // inbound | outbound
  final String status; // ringing, in_progress, completed, rejected, missed, failed
  final int? sessionId;
  final String? callerPhone;
  final String? calleePhone;
  final String? remotePhone;
  final String? duration; // formatted "00:12"
  final int? durationSeconds;
  final int? dealId;
  final String? contactName;
  final String? sdpOffer;
  final String? sdpAnswer;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? createdAt;

  const WhatsAppCall({
    required this.id,
    this.callId,
    required this.direction,
    required this.status,
    this.sessionId,
    this.callerPhone,
    this.calleePhone,
    this.remotePhone,
    this.duration,
    this.durationSeconds,
    this.dealId,
    this.contactName,
    this.sdpOffer,
    this.sdpAnswer,
    this.startedAt,
    this.endedAt,
    this.createdAt,
  });

  bool get isInbound => direction == 'inbound';
  bool get isOutbound => direction == 'outbound';
  bool get isInProgress => status == 'in_progress';
  bool get isRinging => status == 'ringing';
  bool get isTerminated => const {
    'completed',
    'rejected',
    'missed',
    'failed',
    'terminated',
  }.contains(status);

  String? get displayPhone =>
      remotePhone ?? (isInbound ? callerPhone : calleePhone);

  WhatsAppCall copyWith({
    int? id,
    String? callId,
    String? direction,
    String? status,
    int? sessionId,
    String? callerPhone,
    String? calleePhone,
    String? remotePhone,
    String? duration,
    int? durationSeconds,
    int? dealId,
    String? contactName,
    String? sdpOffer,
    String? sdpAnswer,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? createdAt,
  }) {
    return WhatsAppCall(
      id: id ?? this.id,
      callId: callId ?? this.callId,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      sessionId: sessionId ?? this.sessionId,
      callerPhone: callerPhone ?? this.callerPhone,
      calleePhone: calleePhone ?? this.calleePhone,
      remotePhone: remotePhone ?? this.remotePhone,
      duration: duration ?? this.duration,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      dealId: dealId ?? this.dealId,
      contactName: contactName ?? this.contactName,
      sdpOffer: sdpOffer ?? this.sdpOffer,
      sdpAnswer: sdpAnswer ?? this.sdpAnswer,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    callId,
    direction,
    status,
    sessionId,
    callerPhone,
    calleePhone,
    remotePhone,
    duration,
    durationSeconds,
    dealId,
    contactName,
    sdpOffer,
    sdpAnswer,
    startedAt,
    endedAt,
    createdAt,
  ];
}

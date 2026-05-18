import 'package:equatable/equatable.dart';

class CallSession extends Equatable {
  final int id;
  final String? sessionName;
  final String? phoneNumber;
  final String? phoneNumberId;
  final String? status;
  final String? realtimeChannel;

  const CallSession({
    required this.id,
    this.sessionName,
    this.phoneNumber,
    this.phoneNumberId,
    this.status,
    this.realtimeChannel,
  });

  @override
  List<Object?> get props => [
    id,
    sessionName,
    phoneNumber,
    phoneNumberId,
    status,
    realtimeChannel,
  ];
}

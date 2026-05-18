import 'package:equatable/equatable.dart';

class CallPermission extends Equatable {
  final bool granted;
  final String? state; // مثل: granted | denied | pending | unknown
  final DateTime? expiresAt;
  final DateTime? requestedAt;
  final Map<String, dynamic>? raw;

  const CallPermission({
    required this.granted,
    this.state,
    this.expiresAt,
    this.requestedAt,
    this.raw,
  });

  @override
  List<Object?> get props => [granted, state, expiresAt, requestedAt, raw];
}

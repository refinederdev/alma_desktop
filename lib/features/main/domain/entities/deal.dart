import 'package:equatable/equatable.dart';

import 'crm_session.dart';
import 'deal_last_message.dart';
import 'deal_user.dart';

class Deal extends Equatable {
  final int id;
  final int crmSessionId;
  final int userId;
  final String? contactPhone;
  final String? contactName;
  final String? remoteJid;
  final String? senderLid;
  final String? title;
  final String? notes;
  final String status;
  final DateTime? wonAt;
  final DateTime? lostAt;
  final DateTime? assignedAt;
  final DateTime? timeoutAt;
  final int routingAttempts;
  final num totalPaid;
  final int pendingPaymentsCount;
  final bool isOpen;
  final bool isWon;
  final bool isLost;
  final bool isAssigned;
  final DealUser? user;
  final CrmSession? crmSession;
  final DealLastMessage? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Deal({
    required this.id,
    required this.crmSessionId,
    required this.userId,
    this.contactPhone,
    this.contactName,
    this.remoteJid,
    this.senderLid,
    this.title,
    this.notes,
    required this.status,
    this.wonAt,
    this.lostAt,
    this.assignedAt,
    this.timeoutAt,
    required this.routingAttempts,
    required this.totalPaid,
    required this.pendingPaymentsCount,
    required this.isOpen,
    required this.isWon,
    required this.isLost,
    required this.isAssigned,
    this.user,
    this.crmSession,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        crmSessionId,
        userId,
        contactPhone,
        contactName,
        remoteJid,
        senderLid,
        title,
        notes,
        status,
        wonAt,
        lostAt,
        assignedAt,
        timeoutAt,
        routingAttempts,
        totalPaid,
        pendingPaymentsCount,
        isOpen,
        isWon,
        isLost,
        isAssigned,
        user,
        crmSession,
        lastMessage,
        createdAt,
        updatedAt,
      ];
}

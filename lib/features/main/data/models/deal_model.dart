import 'package:alma_desktop/features/main/data/models/crm_session_model.dart';
import 'package:alma_desktop/features/main/data/models/deal_last_message_model.dart';
import 'package:alma_desktop/features/main/data/models/deal_user_model.dart';
import 'package:alma_desktop/features/main/domain/entities/deal.dart';
import 'package:alma_desktop/features/main/domain/entities/deal_last_message.dart';

class DealModel extends Deal {
  const DealModel({
    required super.id,
    required super.crmSessionId,
    required super.userId,
    super.contactPhone,
    super.contactName,
    super.remoteJid,
    super.senderLid,
    super.title,
    super.notes,
    required super.status,
    super.wonAt,
    super.lostAt,
    super.assignedAt,
    super.timeoutAt,
    required super.routingAttempts,
    required super.totalPaid,
    required super.pendingPaymentsCount,
    required super.isOpen,
    required super.isWon,
    required super.isLost,
    required super.isAssigned,
    super.user,
    super.crmSession,
    super.lastMessage,
    required super.createdAt,
    required super.updatedAt,
  }) : super();

  /// يتحقق من أن الـ JSON يحتوي الحقول المطلوبة (مفيد لبيانات Reverb/WebSocket التي قد تكون ناقصة)
  static bool canParseFromJson(Map<String, dynamic> json) {
    return json['id'] != null &&
        json['crm_session_id'] != null &&
        json['created_at'] != null &&
        json['updated_at'] != null;
  }

  factory DealModel.fromJson(Map<String, dynamic> json) => DealModel(
    id: json['id'] as int,
    crmSessionId: json['crm_session_id'] as int,
    userId: (json['user_id'] as num?)?.toInt() ?? 0,
    contactPhone: json['contact_phone'] as String?,
    contactName: json['contact_name'] as String?,
    remoteJid: json['remote_jid'] as String?,
    senderLid: json['sender_lid'] as String?,
    title: json['title'] as String?,
    notes: json['notes'] as String?,
    status: json['status'] as String? ?? 'open',
    wonAt: json['won_at'] != null
        ? DateTime.parse(json['won_at'] as String)
        : null,
    lostAt: json['lost_at'] != null
        ? DateTime.parse(json['lost_at'] as String)
        : null,
    assignedAt: json['assigned_at'] != null
        ? DateTime.parse(json['assigned_at'] as String)
        : null,
    timeoutAt: json['timeout_at'] != null
        ? DateTime.parse(json['timeout_at'] as String)
        : null,
    routingAttempts: (json['routing_attempts'] as num?)?.toInt() ?? 0,
    totalPaid: (json['total_paid'] as num?) ?? 0,
    pendingPaymentsCount:
        (json['pending_payments_count'] as num?)?.toInt() ?? 0,
    isOpen: json['is_open'] as bool? ?? false,
    isWon: json['is_won'] as bool? ?? false,
    isLost: json['is_lost'] as bool? ?? false,
    isAssigned: json['is_assigned'] as bool? ?? false,
    user: json['user'] != null
        ? DealUserModel.fromJson(json['user'] as Map<String, dynamic>)
        : null,
    crmSession: json['crm_session'] != null
        ? CrmSessionModel.fromJson(json['crm_session'] as Map<String, dynamic>)
        : null,
    lastMessage: json['last_message'] != null
        ? DealLastMessageModel.fromJson(
            json['last_message'] as Map<String, dynamic>,
          )
        : null,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'crm_session_id': crmSessionId,
    'user_id': userId,
    'contact_phone': contactPhone,
    'contact_name': contactName,
    'remote_jid': remoteJid,
    'sender_lid': senderLid,
    'title': title,
    'notes': notes,
    'status': status,
    'won_at': wonAt?.toIso8601String(),
    'lost_at': lostAt?.toIso8601String(),
    'assigned_at': assignedAt?.toIso8601String(),
    'timeout_at': timeoutAt?.toIso8601String(),
    'routing_attempts': routingAttempts,
    'total_paid': totalPaid,
    'pending_payments_count': pendingPaymentsCount,
    'is_open': isOpen,
    'is_won': isWon,
    'is_lost': isLost,
    'is_assigned': isAssigned,
    'user': user != null && user is DealUserModel
        ? (user! as DealUserModel).toJson()
        : null,
    'crm_session': crmSession != null && crmSession is CrmSessionModel
        ? (crmSession! as CrmSessionModel).toJson()
        : null,
    'last_message': lastMessage != null && lastMessage is DealLastMessageModel
        ? (lastMessage! as DealLastMessageModel).toJson()
        : null,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  /// إنشاء نسخة من الصفقة مع آخر رسالة محدثة (مفيد عند استلام رسالة جديدة عبر Reverb)
  static DealModel fromDealWithLastMessage(
    Deal deal,
    DealLastMessage? lastMessage,
  ) {
    return DealModel(
      id: deal.id,
      crmSessionId: deal.crmSessionId,
      userId: deal.userId,
      contactPhone: deal.contactPhone,
      contactName: deal.contactName,
      remoteJid: deal.remoteJid,
      senderLid: deal.senderLid,
      title: deal.title,
      notes: deal.notes,
      status: deal.status,
      wonAt: deal.wonAt,
      lostAt: deal.lostAt,
      assignedAt: deal.assignedAt,
      timeoutAt: deal.timeoutAt,
      routingAttempts: deal.routingAttempts,
      totalPaid: deal.totalPaid,
      pendingPaymentsCount: deal.pendingPaymentsCount,
      isOpen: deal.isOpen,
      isWon: deal.isWon,
      isLost: deal.isLost,
      isAssigned: deal.isAssigned,
      user: deal.user,
      crmSession: deal.crmSession,
      lastMessage: lastMessage,
      createdAt: deal.createdAt,
      updatedAt: deal.updatedAt,
    );
  }
}

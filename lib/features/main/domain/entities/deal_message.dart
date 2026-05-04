import 'package:alma_desktop/features/main/domain/entities/crm_session.dart';
import 'package:equatable/equatable.dart';

class DealMessage extends Equatable {
  final int id;
  final int dealId;
  final int crmSessionId;
  final String messageId;
  final bool fromMe;
  final bool isAutoWelcome;
  final bool isWorkflowMessage;
  final String remoteJid;
  final String? senderPn;
  final String cleanedSenderPn;
  final String? senderLid;
  final String? addressingMode;
  final int messageTimestamp;
  final String? pushName;
  final bool broadcast;
  final int? status;
  final DateTime? editedAt;
  final String messageType;
  final String messageTypeDisplay;
  final String? messageBody;
  final String? verifiedBizName;
  final bool hasMediaContent;
  final String? mediaUrl;
  final String? mediaType;
  final String? mediaFileSha256;
  final int? mediaFileLength;
  final int? mediaHeight;
  final int? mediaWidth;
  final dynamic pollData;
  final dynamic contextInfo;
  final CrmSession crmSession;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DealMessage({
    required this.id,
    required this.dealId,
    required this.crmSessionId,
    required this.messageId,
    required this.fromMe,
    required this.isAutoWelcome,
    required this.isWorkflowMessage,
    required this.remoteJid,
    this.senderPn,
    required this.cleanedSenderPn,
    this.senderLid,
    this.addressingMode,
    required this.messageTimestamp,
    this.pushName,
    required this.broadcast,
    this.status,
    this.editedAt,
    required this.messageType,
    required this.messageTypeDisplay,
    this.messageBody,
    this.verifiedBizName,
    required this.hasMediaContent,
    this.mediaUrl,
    this.mediaType,
    this.mediaFileSha256,
    this.mediaFileLength,
    this.mediaHeight,
    this.mediaWidth,
    this.pollData,
    this.contextInfo,
    required this.crmSession,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    dealId,
    crmSessionId,
    messageId,
    fromMe,
    isAutoWelcome,
    isWorkflowMessage,
    remoteJid,
    senderPn,
    cleanedSenderPn,
    senderLid,
    addressingMode,
    messageTimestamp,
    pushName,
    broadcast,
    status,
    editedAt,
    messageType,
    messageTypeDisplay,
    messageBody,
    verifiedBizName,
    hasMediaContent,
    mediaUrl,
    mediaType,
    mediaFileSha256,
    mediaFileLength,
    mediaHeight,
    mediaWidth,
    pollData,
    contextInfo,
    crmSession,
    createdAt,
    updatedAt,
  ];
}

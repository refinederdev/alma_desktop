import 'package:alma_desktop/features/main/domain/entities/deal_last_message.dart';

class DealLastMessageModel extends DealLastMessage {
  const DealLastMessageModel({
    required super.id,
    required super.dealId,
    required super.crmSessionId,
    required super.messageId,
    required super.fromMe,
    required super.isAutoWelcome,
    required super.isWorkflowMessage,
    super.remoteJid,
    super.senderPn,
    super.cleanedSenderPn,
    super.senderLid,
    super.addressingMode,
    required super.messageTimestamp,
    super.pushName,
    required super.broadcast,
    required super.status,
    super.editedAt,
    super.messageType,
    super.messageTypeDisplay,
    super.messageBody,
    super.verifiedBizName,
    required super.hasMediaContent,
    super.mediaUrl,
    super.mediaType,
    super.mediaFileSha256,
    super.mediaFileLength,
    super.mediaHeight,
    super.mediaWidth,
    super.pollData,
    super.contextInfo,
    required super.createdAt,
    required super.updatedAt,
  }) : super();

  factory DealLastMessageModel.fromJson(Map<String, dynamic> json) =>
      DealLastMessageModel(
        id: json['id'] as int,
        dealId: json['deal_id'] as int,
        crmSessionId: json['crm_session_id'] as int,
        messageId: json['message_id'] as String,
        fromMe: json['from_me'] as bool? ?? false,
        isAutoWelcome: json['is_auto_welcome'] as bool? ?? false,
        isWorkflowMessage: json['is_workflow_message'] as bool? ?? false,
        remoteJid: json['remote_jid'] as String?,
        senderPn: json['sender_pn'] as String?,
        cleanedSenderPn: json['cleaned_sender_pn'] as String?,
        senderLid: json['sender_lid'] as String?,
        addressingMode: json['addressing_mode'] as String?,
        messageTimestamp: (json['message_timestamp'] as num?)?.toInt() ?? 0,
        pushName: json['push_name'] as String?,
        broadcast: json['broadcast'] as bool? ?? false,
        status: (json['status'] as num?)?.toInt() ?? 0,
        editedAt: json['edited_at'] != null
            ? DateTime.parse(json['edited_at'] as String)
            : null,
        messageType: json['message_type'] as String?,
        messageTypeDisplay: json['message_type_display'] as String?,
        messageBody: json['message_body'] as String?,
        verifiedBizName: json['verified_biz_name'] as String?,
        hasMediaContent: json['has_media_content'] as bool? ?? false,
        mediaUrl: json['media_url'] as String?,
        mediaType: json['media_type'] as String?,
        mediaFileSha256: json['media_file_sha256'] as String?,
        mediaFileLength: (json['media_file_length'] as num?)?.toInt(),
        mediaHeight: (json['media_height'] as num?)?.toInt(),
        mediaWidth: (json['media_width'] as num?)?.toInt(),
        pollData: json['poll_data'],
        contextInfo: json['context_info'],
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  /// إنشاء آخر رسالة من بيانات Reverb (حدث message.received)
  static DealLastMessageModel fromReverbPayload(
    Map<String, dynamic> message,
    int dealId,
    int crmSessionId,
  ) {
    final dbIdRaw = message['db_id'] ?? message['id'];
    final dbId = dbIdRaw is int
        ? dbIdRaw
        : (dbIdRaw is num
              ? dbIdRaw.toInt()
              : int.tryParse(dbIdRaw?.toString() ?? '') ?? 0);
    final ts =
        (message['timestamp'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final createdAt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return DealLastMessageModel(
      id: dbId,
      dealId: dealId,
      crmSessionId: crmSessionId,
      messageId:
          message['id'] as String? ?? message['message_id'] as String? ?? '',
      fromMe: message['from_me'] as bool? ?? false,
      isAutoWelcome: false,
      isWorkflowMessage: false,
      messageTimestamp: ts,
      pushName: message['push_name'] as String?,
      broadcast: false,
      status: 0,
      messageType: message['message_type'] as String? ?? 'conversation',
      messageTypeDisplay:
          message['message_type_display'] as String? ??
          message['message_type'] as String? ??
          'conversation',
      messageBody: message['message_body'] as String?,
      hasMediaContent:
          message['has_media'] as bool? ??
          message['has_media_content'] as bool? ??
          false,
      mediaUrl: message['media_url'] as String?,
      mediaType: message['media_type'] as String?,
      mediaFileSha256: message['media_file_sha256'] as String?,
      mediaFileLength: (message['media_file_length'] as num?)?.toInt(),
      mediaHeight: (message['media_height'] as num?)?.toInt(),
      mediaWidth: (message['media_width'] as num?)?.toInt(),
      pollData: message['poll_data'],
      contextInfo: message['quoted_message'],
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'deal_id': dealId,
    'crm_session_id': crmSessionId,
    'message_id': messageId,
    'from_me': fromMe,
    'is_auto_welcome': isAutoWelcome,
    'is_workflow_message': isWorkflowMessage,
    'remote_jid': remoteJid,
    'sender_pn': senderPn,
    'cleaned_sender_pn': cleanedSenderPn,
    'sender_lid': senderLid,
    'addressing_mode': addressingMode,
    'message_timestamp': messageTimestamp,
    'push_name': pushName,
    'broadcast': broadcast,
    'status': status,
    'edited_at': editedAt?.toIso8601String(),
    'message_type': messageType,
    'message_type_display': messageTypeDisplay,
    'message_body': messageBody,
    'verified_biz_name': verifiedBizName,
    'has_media_content': hasMediaContent,
    'media_url': mediaUrl,
    'media_type': mediaType,
    'media_file_sha256': mediaFileSha256,
    'media_file_length': mediaFileLength,
    'media_height': mediaHeight,
    'media_width': mediaWidth,
    'poll_data': pollData,
    'context_info': contextInfo,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

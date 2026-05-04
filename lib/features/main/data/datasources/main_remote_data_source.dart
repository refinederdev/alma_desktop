import 'dart:io';

import 'package:alma_desktop/core/api/api_consumer.dart';
import 'package:alma_desktop/core/services/paginator/paginator.dart';
import 'package:alma_desktop/features/main/data/models/agent_model.dart';
import 'package:alma_desktop/features/main/data/models/attendance_model.dart';
import 'package:alma_desktop/features/main/data/models/attendance_time_total_model.dart';
import 'package:alma_desktop/features/main/data/models/attendance_weekly_stat_model.dart';
import 'package:alma_desktop/features/main/data/models/deal_message_model.dart';
import 'package:alma_desktop/features/main/data/models/deal_model.dart';
import 'package:alma_desktop/features/main/data/models/deal_stats_model.dart';
import 'package:alma_desktop/features/main/data/models/message_line_chart_data_model.dart';
import 'package:alma_desktop/features/main/data/models/message_stats_model.dart';
import 'package:alma_desktop/features/main/data/models/notification_model.dart';
import 'package:alma_desktop/features/main/data/models/notification_unread_count_model.dart';
import 'package:dio/dio.dart' as dio;

abstract class MainRemoteDataSource {
  Future<PaginatorModel<DealModel>> getOpenDeals({
    int page = 1,
    int perPage = 15,
  });

  Future<PaginatorModel<DealModel>> getLostDeals({
    int page = 1,
    int perPage = 15,
  });

  Future<PaginatorModel<DealModel>> getWonDeals({
    int page = 1,
    int perPage = 15,
  });

  Future<DealModel> getDealById(int id);

  Future<PaginatorModel<DealMessageModel>> getDealMessages(
    int dealId, {
    int page = 1,
    int perPage = 50,
  });

  Future<DealMessageModel> sendMessage({
    required int dealId,
    String? messageBody,
    String? messageType,
    required bool fromMe,
    String? mediaPath,
  });

  Future<List<AgentModel>> getAgents({String? search});

  Future<DealModel> assignDeal({required int dealId, required int userId});

  Future<DealModel> updateDeal(
    int dealId, {
    String? contactName,
    String? title,
    String? notes,
    int? userId,
    String? status,
  });

  Future<AttendanceModel> checkIn({String? notes});

  Future<AttendanceModel> checkOut({String? notes});

  Future<AttendanceModel> getAttendanceStatus();

  Future<AttendanceTimeTotalModel> getTodayTotal();

  Future<AttendanceTimeTotalModel> getWeekTotal();

  Future<List<AttendanceWeeklyStatModel>> getWeeklyStats();

  Future<DealStatsModel> getDealsStats();

  Future<MessageStatsModel> getMessagesStats();

  Future<List<MessageLineChartDataModel>> getMessagesLineChart();

  Future<PaginatorModel<NotificationModel>> getNotifications({
    int page = 1,
    int perPage = 20,
  });

  Future<NotificationUnreadCountModel> getNotificationsUnreadCount();

  Future<NotificationUnreadCountModel> markAllNotificationsAsRead();

  Future<NotificationUnreadCountModel> markNotificationAsRead(
    String notificationId,
  );

  Future<NotificationUnreadCountModel> deleteNotification(
    String notificationId,
  );
}

class MainRemoteDataSourceImpl implements MainRemoteDataSource {
  final ApiConsumer apiConsumer;

  MainRemoteDataSourceImpl({required this.apiConsumer});

  @override
  Future<PaginatorModel<DealModel>> getOpenDeals({
    int page = 1,
    int perPage = 15,
  }) async {
    final response = await apiConsumer.get(
      'deals/open',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return PaginatorModel<DealModel>.fromJson(
      response as Map<String, dynamic>,
      (m) => DealModel.fromJson(m),
    );
  }

  @override
  Future<PaginatorModel<DealModel>> getLostDeals({
    int page = 1,
    int perPage = 15,
  }) async {
    final response = await apiConsumer.get(
      'deals/lost',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return PaginatorModel<DealModel>.fromJson(
      response as Map<String, dynamic>,
      (m) => DealModel.fromJson(m),
    );
  }

  @override
  Future<PaginatorModel<DealModel>> getWonDeals({
    int page = 1,
    int perPage = 15,
  }) async {
    final response = await apiConsumer.get(
      'deals/won',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return PaginatorModel<DealModel>.fromJson(
      response as Map<String, dynamic>,
      (m) => DealModel.fromJson(m),
    );
  }

  @override
  Future<DealModel> getDealById(int id) async {
    final response = await apiConsumer.get('deals/$id');
    return DealModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<PaginatorModel<DealMessageModel>> getDealMessages(
    int dealId, {
    int page = 1,
    int perPage = 50,
  }) async {
    final response = await apiConsumer.get(
      'messages/deal/$dealId',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return PaginatorModel<DealMessageModel>.fromJson(
      response as Map<String, dynamic>,
      (m) => DealMessageModel.fromJson(m),
    );
  }

  @override
  Future<DealMessageModel> sendMessage({
    required int dealId,
    String? messageBody,
    String? messageType,
    required bool fromMe,
    String? mediaPath,
  }) async {
    // إعداد Map للبيانات
    // ملاحظة: FormData.fromMap() يحول boolean إلى string
    // Laravel validation rule 'boolean' يقبل: true, false, "true", "false", "1", "0", 1, 0
    // لذا نستخدم "true" كـ string مباشرة
    final Map<String, dynamic> formDataMap = {
      'deal_id': dealId,
      'from_me': 1, // دائماً "true" لأن المستخدم هو المرسل
    };

    if (messageBody != null && messageBody.isNotEmpty) {
      formDataMap['message_body'] = messageBody;
    }

    if (messageType != null && messageType.isNotEmpty) {
      formDataMap['message_type'] = messageType;
    }

    // إضافة الملف إذا كان موجوداً
    if (mediaPath != null && mediaPath.isNotEmpty) {
      final file = File(mediaPath);
      if (await file.exists()) {
        final fileName = file.path.split('/').last;
        formDataMap['media'] = await dio.MultipartFile.fromFile(
          mediaPath,
          filename: fileName,
        );
      }
    }

    final response = await apiConsumer.post(
      'messages',
      body: formDataMap,
      isFormData: true,
    );

    return DealMessageModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<List<AgentModel>> getAgents({String? search}) async {
    final response = await apiConsumer.get(
      'deals/agents',
      queryParameters: search != null && search.isNotEmpty
          ? {'search': search}
          : null,
    );

    // الاستجابة تأتي كقائمة مباشرة (dio_consumer يرجع data مباشرة)
    final data = response as List<dynamic>? ?? [];
    return data
        .map((json) => AgentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DealModel> assignDeal({
    required int dealId,
    required int userId,
  }) async {
    final response = await apiConsumer.post(
      'deals/$dealId/assign',
      body: {'user_id': userId},
    );
    return DealModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<DealModel> updateDeal(
    int dealId, {
    String? contactName,
    String? title,
    String? notes,
    int? userId,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    if (contactName != null) body['contact_name'] = contactName;
    if (title != null) body['title'] = title;
    if (notes != null) body['notes'] = notes;
    if (userId != null) body['user_id'] = userId;
    if (status != null) body['status'] = status;

    final response = await apiConsumer.put(
      'deals/$dealId',
      body: body.isNotEmpty ? body : null,
    );
    return DealModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<AttendanceModel> checkIn({String? notes}) async {
    final body = <String, dynamic>{};
    if (notes != null && notes.isNotEmpty) {
      body['notes'] = notes;
    }

    final response = await apiConsumer.post(
      'attendance/check-in',
      body: body.isNotEmpty ? body : null,
    );
    return AttendanceModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<AttendanceModel> checkOut({String? notes}) async {
    final body = <String, dynamic>{};
    if (notes != null && notes.isNotEmpty) {
      body['notes'] = notes;
    }

    final response = await apiConsumer.post(
      'attendance/check-out',
      body: body.isNotEmpty ? body : null,
    );
    return AttendanceModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<AttendanceModel> getAttendanceStatus() async {
    final response = await apiConsumer.get('attendance/status');
    return AttendanceModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<AttendanceTimeTotalModel> getTodayTotal() async {
    final response = await apiConsumer.get('attendance/today-total');
    return AttendanceTimeTotalModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<AttendanceTimeTotalModel> getWeekTotal() async {
    final response = await apiConsumer.get('attendance/week-total');
    return AttendanceTimeTotalModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<List<AttendanceWeeklyStatModel>> getWeeklyStats() async {
    final response = await apiConsumer.get('attendance/weekly-stats');
    final data = response as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? [];
    return list
        .map(
          (json) =>
              AttendanceWeeklyStatModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<DealStatsModel> getDealsStats() async {
    final response = await apiConsumer.get('deals/stats');
    return DealStatsModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<MessageStatsModel> getMessagesStats() async {
    final response = await apiConsumer.get('messages/stats');
    return MessageStatsModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<List<MessageLineChartDataModel>> getMessagesLineChart() async {
    final response = await apiConsumer.get('messages/linechart');
    // dio_consumer يرجع data مباشرة إذا كانت موجودة
    // إذا كانت الاستجابة List مباشرة
    if (response is List) {
      final data = response as List<dynamic>? ?? [];
      return data
          .map(
            (json) => MessageLineChartDataModel.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    }
    // إذا كانت الاستجابة Map مع data
    if (response is Map<String, dynamic>) {
      final data = response['data'] as List<dynamic>? ?? [];
      return data
          .map(
            (json) => MessageLineChartDataModel.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    }
    return [];
  }

  @override
  Future<PaginatorModel<NotificationModel>> getNotifications({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await apiConsumer.get(
      'notifications',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return PaginatorModel<NotificationModel>.fromJson(
      response as Map<String, dynamic>,
      (m) => NotificationModel.fromJson(m),
    );
  }

  @override
  Future<NotificationUnreadCountModel> getNotificationsUnreadCount() async {
    final response = await apiConsumer.get('notifications/unread-count');
    return NotificationUnreadCountModel.fromJson(
      response as Map<String, dynamic>,
    );
  }

  @override
  Future<NotificationUnreadCountModel> markAllNotificationsAsRead() async {
    final response = await apiConsumer.post(
      'notifications/mark-all-read',
      body: null,
    );
    return NotificationUnreadCountModel.fromJson(
      response as Map<String, dynamic>,
    );
  }

  @override
  Future<NotificationUnreadCountModel> markNotificationAsRead(
    String notificationId,
  ) async {
    final response = await apiConsumer.post(
      'notifications/$notificationId/read',
      body: null,
    );
    return NotificationUnreadCountModel.fromJson(
      response as Map<String, dynamic>,
    );
  }

  @override
  Future<NotificationUnreadCountModel> deleteNotification(
    String notificationId,
  ) async {
    final response = await apiConsumer.delete('notifications/$notificationId');
    return NotificationUnreadCountModel.fromJson(
      response as Map<String, dynamic>,
    );
  }
}

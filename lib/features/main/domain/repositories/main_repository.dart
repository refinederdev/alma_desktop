import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/services/paginator/paginator.dart';
import 'package:alma_desktop/features/main/domain/entities/agent.dart';
import 'package:alma_desktop/features/main/domain/entities/attendance.dart';
import 'package:alma_desktop/features/main/domain/entities/attendance_time_total.dart';
import 'package:alma_desktop/features/main/domain/entities/attendance_weekly_stat.dart';
import 'package:alma_desktop/features/main/domain/entities/company_location.dart';
import 'package:alma_desktop/features/main/domain/entities/deal.dart';
import 'package:alma_desktop/features/main/domain/entities/deal_message.dart';
import 'package:alma_desktop/features/main/domain/entities/deal_stats.dart';
import 'package:alma_desktop/features/main/domain/entities/message_line_chart_data.dart';
import 'package:alma_desktop/features/main/domain/entities/message_stats.dart';
import 'package:alma_desktop/features/main/domain/entities/notification.dart';
import 'package:alma_desktop/features/main/domain/entities/notification_unread_count.dart';
import 'package:dartz/dartz.dart';

abstract class MainRepository {
  Future<Either<Failure, List<CompanyLocation>>> getCompanyLocations({
    bool? activeOnly,
    bool? isActive,
  });

  Future<Either<Failure, Paginator<Deal>>> getOpenDeals({
    int page = 1,
    int perPage = 15,
  });

  Future<Either<Failure, Paginator<Deal>>> getLostDeals({
    int page = 1,
    int perPage = 15,
  });

  Future<Either<Failure, Paginator<Deal>>> getWonDeals({
    int page = 1,
    int perPage = 15,
  });

  Future<Either<Failure, Deal>> getDealById(int id);

  Future<Either<Failure, Paginator<DealMessage>>> getDealMessages(
    int dealId, {
    int page = 1,
    int perPage = 50,
  });

  Future<Either<Failure, DealMessage>> sendMessage({
    required int dealId,
    String? messageBody,
    String? messageType,
    required bool fromMe,
    String? mediaPath,
    int? locationId,
  });

  Future<Either<Failure, DealMessage>> updateMessage({
    required int messageId,
    String? messageBody,
    String? mediaUrl,
    String? mediaType,
  });

  Future<Either<Failure, void>> deleteMessage({required int messageId});

  Future<Either<Failure, List<Agent>>> getAgents({String? search});

  Future<Either<Failure, Deal>> assignDeal({
    required int dealId,
    required int userId,
  });

  Future<Either<Failure, Deal>> updateDeal(
    int dealId, {
    String? contactName,
    String? title,
    String? notes,
    int? userId,
    String? status,
  });

  Future<Either<Failure, Attendance>> checkIn({String? notes});

  Future<Either<Failure, Attendance>> checkOut({String? notes});

  Future<Either<Failure, Attendance>> getAttendanceStatus();

  Future<Either<Failure, AttendanceTimeTotal>> getTodayTotal();

  Future<Either<Failure, AttendanceTimeTotal>> getWeekTotal();

  Future<Either<Failure, List<AttendanceWeeklyStat>>> getWeeklyStats();

  Future<Either<Failure, DealStats>> getDealsStats();

  Future<Either<Failure, MessageStats>> getMessagesStats();

  Future<Either<Failure, List<MessageLineChartData>>> getMessagesLineChart();

  Future<Either<Failure, Paginator<Notification>>> getNotifications({
    int page = 1,
    int perPage = 20,
  });

  Future<Either<Failure, NotificationUnreadCount>>
  getNotificationsUnreadCount();

  Future<Either<Failure, NotificationUnreadCount>> markAllNotificationsAsRead();

  Future<Either<Failure, NotificationUnreadCount>> markNotificationAsRead(
    String notificationId,
  );

  Future<Either<Failure, NotificationUnreadCount>> deleteNotification(
    String notificationId,
  );
}

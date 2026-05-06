import 'package:alma_desktop/core/errors/exceptions.dart';
import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/services/paginator/paginator.dart';
import 'package:alma_desktop/features/main/data/datasources/main_remote_data_source.dart';
import 'package:alma_desktop/features/main/domain/entities/agent.dart';
import 'package:alma_desktop/features/main/domain/entities/attendance.dart';
import 'package:alma_desktop/features/main/domain/entities/attendance_time_total.dart';
import 'package:alma_desktop/features/main/domain/entities/attendance_weekly_stat.dart';
import 'package:alma_desktop/features/main/domain/entities/deal.dart';
import 'package:alma_desktop/features/main/domain/entities/deal_message.dart';
import 'package:alma_desktop/features/main/domain/entities/deal_stats.dart';
import 'package:alma_desktop/features/main/domain/entities/message_line_chart_data.dart';
import 'package:alma_desktop/features/main/domain/entities/message_stats.dart';
import 'package:alma_desktop/features/main/domain/entities/notification.dart';
import 'package:alma_desktop/features/main/domain/entities/notification_unread_count.dart';
import 'package:alma_desktop/features/main/domain/repositories/main_repository.dart';
import 'package:dartz/dartz.dart';

class MainRepositoryImpl implements MainRepository {
  final MainRemoteDataSource mainRemoteDataSource;

  MainRepositoryImpl({required this.mainRemoteDataSource});

  @override
  Future<Either<Failure, Paginator<Deal>>> getOpenDeals({
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final result = await mainRemoteDataSource.getOpenDeals(
        page: page,
        perPage: perPage,
      );
      final paginator = Paginator<Deal>(
        data: List<Deal>.from(result.data),
        currentPage: result.currentPage,
        perPage: result.perPage,
        total: result.total,
        lastPage: result.lastPage,
        from: result.from,
        to: result.to,
        hasMorePages: result.hasMorePages,
      );
      return Right(paginator);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message));
    }
  }

  @override
  Future<Either<Failure, Paginator<Deal>>> getLostDeals({
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final result = await mainRemoteDataSource.getLostDeals(
        page: page,
        perPage: perPage,
      );
      final paginator = Paginator<Deal>(
        data: List<Deal>.from(result.data),
        currentPage: result.currentPage,
        perPage: result.perPage,
        total: result.total,
        lastPage: result.lastPage,
        from: result.from,
        to: result.to,
        hasMorePages: result.hasMorePages,
      );
      return Right(paginator);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message));
    }
  }

  @override
  Future<Either<Failure, Paginator<Deal>>> getWonDeals({
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final result = await mainRemoteDataSource.getWonDeals(
        page: page,
        perPage: perPage,
      );
      final paginator = Paginator<Deal>(
        data: List<Deal>.from(result.data),
        currentPage: result.currentPage,
        perPage: result.perPage,
        total: result.total,
        lastPage: result.lastPage,
        from: result.from,
        to: result.to,
        hasMorePages: result.hasMorePages,
      );
      return Right(paginator);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message));
    }
  }

  @override
  Future<Either<Failure, Deal>> getDealById(int id) async {
    try {
      final result = await mainRemoteDataSource.getDealById(id);
      return Right(result);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message));
    }
  }

  @override
  Future<Either<Failure, Paginator<DealMessage>>> getDealMessages(
    int dealId, {
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final result = await mainRemoteDataSource.getDealMessages(
        dealId,
        page: page,
        perPage: perPage,
      );
      final paginator = Paginator<DealMessage>(
        data: List<DealMessage>.from(result.data),
        currentPage: result.currentPage,
        perPage: result.perPage,
        total: result.total,
        lastPage: result.lastPage,
        from: result.from,
        to: result.to,
        hasMorePages: result.hasMorePages,
      );
      return Right(paginator);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message));
    }
  }

  @override
  Future<Either<Failure, DealMessage>> sendMessage({
    required int dealId,
    String? messageBody,
    String? messageType,
    required bool fromMe,
    String? mediaPath,
  }) async {
    try {
      final result = await mainRemoteDataSource.sendMessage(
        dealId: dealId,
        messageBody: messageBody,
        messageType: messageType,
        fromMe: fromMe,
        mediaPath: mediaPath,
      );
      return Right(result);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message));
    }
  }

  @override
  Future<Either<Failure, DealMessage>> updateMessage({
    required int messageId,
    String? messageBody,
    String? mediaUrl,
    String? mediaType,
  }) async {
    try {
      final result = await mainRemoteDataSource.updateMessage(
        messageId: messageId,
        messageBody: messageBody,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
      );
      return Right(result);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage({required int messageId}) async {
    try {
      await mainRemoteDataSource.deleteMessage(messageId: messageId);
      return Right(null);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<Agent>>> getAgents({String? search}) async {
    try {
      final result = await mainRemoteDataSource.getAgents(search: search);
      return Right(List<Agent>.from(result));
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message));
    }
  }

  @override
  Future<Either<Failure, Deal>> assignDeal({
    required int dealId,
    required int userId,
  }) async {
    try {
      final result = await mainRemoteDataSource.assignDeal(
        dealId: dealId,
        userId: userId,
      );
      return Right(result);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message));
    }
  }

  @override
  Future<Either<Failure, Deal>> updateDeal(
    int dealId, {
    String? contactName,
    String? title,
    String? notes,
    int? userId,
    String? status,
  }) async {
    try {
      final result = await mainRemoteDataSource.updateDeal(
        dealId,
        contactName: contactName,
        title: title,
        notes: notes,
        userId: userId,
        status: status,
      );
      return Right(result);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message));
    }
  }

  @override
  Future<Either<Failure, Attendance>> checkIn({String? notes}) async {
    try {
      final result = await mainRemoteDataSource.checkIn(notes: notes);
      return Right(result);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message));
    }
  }

  @override
  Future<Either<Failure, Attendance>> checkOut({String? notes}) async {
    try {
      final result = await mainRemoteDataSource.checkOut(notes: notes);
      return Right(result);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message));
    }
  }

  @override
  Future<Either<Failure, Attendance>> getAttendanceStatus() async {
    try {
      final result = await mainRemoteDataSource.getAttendanceStatus();
      return Right(result);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message));
    }
  }

  @override
  Future<Either<Failure, AttendanceTimeTotal>> getTodayTotal() async {
    try {
      final result = await mainRemoteDataSource.getTodayTotal();
      return Right(result);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message));
    }
  }

  @override
  Future<Either<Failure, AttendanceTimeTotal>> getWeekTotal() async {
    try {
      final result = await mainRemoteDataSource.getWeekTotal();
      return Right(result);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<AttendanceWeeklyStat>>> getWeeklyStats() async {
    try {
      final result = await mainRemoteDataSource.getWeeklyStats();
      return Right(List<AttendanceWeeklyStat>.from(result));
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message));
    }
  }

  @override
  Future<Either<Failure, DealStats>> getDealsStats() async {
    try {
      final result = await mainRemoteDataSource.getDealsStats();
      return Right(result);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message));
    }
  }

  @override
  Future<Either<Failure, MessageStats>> getMessagesStats() async {
    try {
      final result = await mainRemoteDataSource.getMessagesStats();
      return Right(result);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<MessageLineChartData>>>
  getMessagesLineChart() async {
    try {
      final result = await mainRemoteDataSource.getMessagesLineChart();
      return Right(List<MessageLineChartData>.from(result));
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message));
    }
  }

  @override
  Future<Either<Failure, Paginator<Notification>>> getNotifications({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final result = await mainRemoteDataSource.getNotifications(
        page: page,
        perPage: perPage,
      );
      final paginator = Paginator<Notification>(
        data: List<Notification>.from(result.data),
        currentPage: result.currentPage,
        perPage: result.perPage,
        total: result.total,
        lastPage: result.lastPage,
        from: result.from,
        to: result.to,
        hasMorePages: result.hasMorePages,
      );
      return Right(paginator);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message));
    }
  }

  @override
  Future<Either<Failure, NotificationUnreadCount>>
  getNotificationsUnreadCount() async {
    try {
      final result = await mainRemoteDataSource.getNotificationsUnreadCount();
      return Right(result);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message));
    }
  }

  @override
  Future<Either<Failure, NotificationUnreadCount>>
  markAllNotificationsAsRead() async {
    try {
      final result = await mainRemoteDataSource.markAllNotificationsAsRead();
      return Right(result);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message));
    }
  }

  @override
  Future<Either<Failure, NotificationUnreadCount>> markNotificationAsRead(
    String notificationId,
  ) async {
    try {
      final result = await mainRemoteDataSource.markNotificationAsRead(
        notificationId,
      );
      return Right(result);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message));
    }
  }

  @override
  Future<Either<Failure, NotificationUnreadCount>> deleteNotification(
    String notificationId,
  ) async {
    try {
      final result = await mainRemoteDataSource.deleteNotification(
        notificationId,
      );
      return Right(result);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message));
    }
  }
}

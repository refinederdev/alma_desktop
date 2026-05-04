import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/main/domain/entities/notification_unread_count.dart';
import 'package:alma_desktop/features/main/domain/repositories/main_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class DeleteNotificationUseCase
    implements UseCase<NotificationUnreadCount, DeleteNotificationParams> {
  final MainRepository mainRepository;

  DeleteNotificationUseCase({required this.mainRepository});

  @override
  Future<Either<Failure, NotificationUnreadCount>> call(
    DeleteNotificationParams params,
  ) async {
    return mainRepository.deleteNotification(params.notificationId);
  }
}

class DeleteNotificationParams extends Equatable {
  final String notificationId;

  const DeleteNotificationParams({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/main/domain/entities/notification_unread_count.dart';
import 'package:alma_desktop/features/main/domain/repositories/main_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class MarkNotificationAsReadUseCase
    implements UseCase<NotificationUnreadCount, MarkNotificationAsReadParams> {
  final MainRepository mainRepository;

  MarkNotificationAsReadUseCase({required this.mainRepository});

  @override
  Future<Either<Failure, NotificationUnreadCount>> call(
    MarkNotificationAsReadParams params,
  ) async {
    return mainRepository.markNotificationAsRead(params.notificationId);
  }
}

class MarkNotificationAsReadParams extends Equatable {
  final String notificationId;

  const MarkNotificationAsReadParams({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

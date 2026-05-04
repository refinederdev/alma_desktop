import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/main/domain/entities/notification_unread_count.dart';
import 'package:alma_desktop/features/main/domain/repositories/main_repository.dart';
import 'package:dartz/dartz.dart';

class GetNotificationsUnreadCountUseCase
    implements UseCase<NotificationUnreadCount, NoParams> {
  final MainRepository mainRepository;

  GetNotificationsUnreadCountUseCase({required this.mainRepository});

  @override
  Future<Either<Failure, NotificationUnreadCount>> call(NoParams params) async {
    return mainRepository.getNotificationsUnreadCount();
  }
}

import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/services/paginator/paginator.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/main/domain/entities/notification.dart';
import 'package:alma_desktop/features/main/domain/repositories/main_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class GetNotificationsUseCase
    implements UseCase<Paginator<Notification>, GetNotificationsParams> {
  final MainRepository mainRepository;

  GetNotificationsUseCase({required this.mainRepository});

  @override
  Future<Either<Failure, Paginator<Notification>>> call(
    GetNotificationsParams params,
  ) async {
    return mainRepository.getNotifications(
      page: params.page,
      perPage: params.perPage,
    );
  }
}

class GetNotificationsParams extends Equatable {
  final int page;
  final int perPage;

  const GetNotificationsParams({required this.page, required this.perPage});

  @override
  List<Object?> get props => [page, perPage];
}

import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/main/domain/entities/message_stats.dart';
import 'package:alma_desktop/features/main/domain/repositories/main_repository.dart';
import 'package:dartz/dartz.dart';

class GetMessagesStatsUseCase implements UseCase<MessageStats, NoParams> {
  final MainRepository mainRepository;

  GetMessagesStatsUseCase({required this.mainRepository});

  @override
  Future<Either<Failure, MessageStats>> call(NoParams params) async {
    return mainRepository.getMessagesStats();
  }
}

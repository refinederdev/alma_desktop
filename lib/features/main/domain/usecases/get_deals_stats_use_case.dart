import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/main/domain/entities/deal_stats.dart';
import 'package:alma_desktop/features/main/domain/repositories/main_repository.dart';
import 'package:dartz/dartz.dart';

class GetDealsStatsUseCase implements UseCase<DealStats, NoParams> {
  final MainRepository mainRepository;

  GetDealsStatsUseCase({required this.mainRepository});

  @override
  Future<Either<Failure, DealStats>> call(NoParams params) async {
    return mainRepository.getDealsStats();
  }
}

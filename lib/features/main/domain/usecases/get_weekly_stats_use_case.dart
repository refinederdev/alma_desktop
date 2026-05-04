import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/main/domain/entities/attendance_weekly_stat.dart';
import 'package:alma_desktop/features/main/domain/repositories/main_repository.dart';
import 'package:dartz/dartz.dart';

class GetWeeklyStatsUseCase
    implements UseCase<List<AttendanceWeeklyStat>, NoParams> {
  final MainRepository mainRepository;

  GetWeeklyStatsUseCase({required this.mainRepository});

  @override
  Future<Either<Failure, List<AttendanceWeeklyStat>>> call(
    NoParams params,
  ) async {
    return mainRepository.getWeeklyStats();
  }
}

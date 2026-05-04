import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/main/domain/entities/attendance_time_total.dart';
import 'package:alma_desktop/features/main/domain/repositories/main_repository.dart';
import 'package:dartz/dartz.dart';

class GetWeekTotalUseCase implements UseCase<AttendanceTimeTotal, NoParams> {
  final MainRepository mainRepository;

  GetWeekTotalUseCase({required this.mainRepository});

  @override
  Future<Either<Failure, AttendanceTimeTotal>> call(NoParams params) async {
    return mainRepository.getWeekTotal();
  }
}

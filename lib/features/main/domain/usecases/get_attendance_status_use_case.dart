import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/main/domain/entities/attendance.dart';
import 'package:alma_desktop/features/main/domain/repositories/main_repository.dart';
import 'package:dartz/dartz.dart';

class GetAttendanceStatusUseCase implements UseCase<Attendance, NoParams> {
  final MainRepository mainRepository;

  GetAttendanceStatusUseCase({required this.mainRepository});

  @override
  Future<Either<Failure, Attendance>> call(NoParams params) async {
    return mainRepository.getAttendanceStatus();
  }
}

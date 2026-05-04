import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/main/domain/entities/attendance.dart';
import 'package:alma_desktop/features/main/domain/repositories/main_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class CheckInUseCase implements UseCase<Attendance, CheckInParams> {
  final MainRepository mainRepository;

  CheckInUseCase({required this.mainRepository});

  @override
  Future<Either<Failure, Attendance>> call(CheckInParams params) async {
    return mainRepository.checkIn(notes: params.notes);
  }
}

class CheckInParams extends Equatable {
  final String? notes;

  const CheckInParams({this.notes});

  @override
  List<Object?> get props => [notes];
}

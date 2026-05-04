import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/main/domain/entities/attendance.dart';
import 'package:alma_desktop/features/main/domain/repositories/main_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class CheckOutUseCase implements UseCase<Attendance, CheckOutParams> {
  final MainRepository mainRepository;

  CheckOutUseCase({required this.mainRepository});

  @override
  Future<Either<Failure, Attendance>> call(CheckOutParams params) async {
    return mainRepository.checkOut(notes: params.notes);
  }
}

class CheckOutParams extends Equatable {
  final String? notes;

  const CheckOutParams({this.notes});

  @override
  List<Object?> get props => [notes];
}

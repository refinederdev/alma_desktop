import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/main/domain/entities/deal.dart';
import 'package:alma_desktop/features/main/domain/repositories/main_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class GetDealByIdUseCase implements UseCase<Deal, GetDealByIdParams> {
  final MainRepository mainRepository;

  GetDealByIdUseCase({required this.mainRepository});

  @override
  Future<Either<Failure, Deal>> call(GetDealByIdParams params) async {
    return mainRepository.getDealById(params.id);
  }
}

class GetDealByIdParams extends Equatable {
  final int id;

  const GetDealByIdParams({required this.id});

  @override
  List<Object?> get props => [id];
}

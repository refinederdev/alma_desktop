import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/main/domain/entities/deal.dart';
import 'package:alma_desktop/features/main/domain/repositories/main_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class AssignDealUseCase implements UseCase<Deal, AssignDealParams> {
  final MainRepository mainRepository;

  AssignDealUseCase({required this.mainRepository});

  @override
  Future<Either<Failure, Deal>> call(AssignDealParams params) async {
    return mainRepository.assignDeal(
      dealId: params.dealId,
      userId: params.userId,
    );
  }
}

class AssignDealParams extends Equatable {
  final int dealId;
  final int userId;

  const AssignDealParams({required this.dealId, required this.userId});

  @override
  List<Object?> get props => [dealId, userId];
}

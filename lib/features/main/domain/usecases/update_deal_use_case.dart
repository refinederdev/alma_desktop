import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/main/domain/entities/deal.dart';
import 'package:alma_desktop/features/main/domain/repositories/main_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class UpdateDealUseCase implements UseCase<Deal, UpdateDealParams> {
  final MainRepository mainRepository;

  UpdateDealUseCase({required this.mainRepository});

  @override
  Future<Either<Failure, Deal>> call(UpdateDealParams params) async {
    return mainRepository.updateDeal(
      params.dealId,
      contactName: params.contactName,
      title: params.title,
      notes: params.notes,
      userId: params.userId,
      status: params.status,
    );
  }
}

class UpdateDealParams extends Equatable {
  final int dealId;
  final String? contactName;
  final String? title;
  final String? notes;
  final int? userId;
  final String? status;

  const UpdateDealParams({
    required this.dealId,
    this.contactName,
    this.title,
    this.notes,
    this.userId,
    this.status,
  });

  @override
  List<Object?> get props => [
    dealId,
    contactName,
    title,
    notes,
    userId,
    status,
  ];
}

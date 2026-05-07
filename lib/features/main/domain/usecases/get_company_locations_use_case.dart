import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/main/domain/entities/company_location.dart';
import 'package:alma_desktop/features/main/domain/repositories/main_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class GetCompanyLocationsUseCase
    implements UseCase<List<CompanyLocation>, GetCompanyLocationsParams> {
  final MainRepository mainRepository;

  GetCompanyLocationsUseCase({required this.mainRepository});

  @override
  Future<Either<Failure, List<CompanyLocation>>> call(
    GetCompanyLocationsParams params,
  ) async {
    return mainRepository.getCompanyLocations(
      activeOnly: params.activeOnly,
      isActive: params.isActive,
    );
  }
}

class GetCompanyLocationsParams extends Equatable {
  final bool? activeOnly;
  final bool? isActive;

  const GetCompanyLocationsParams({this.activeOnly, this.isActive});

  @override
  List<Object?> get props => [activeOnly, isActive];
}


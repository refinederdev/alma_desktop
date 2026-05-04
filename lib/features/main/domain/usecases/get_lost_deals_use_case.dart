import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/services/paginator/paginator.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/main/domain/entities/deal.dart';
import 'package:alma_desktop/features/main/domain/repositories/main_repository.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_deals_use_case.dart';
import 'package:dartz/dartz.dart';

class GetLostDealsUseCase implements UseCase<Paginator<Deal>, GetDealsParams> {
  final MainRepository mainRepository;

  GetLostDealsUseCase({required this.mainRepository});

  @override
  Future<Either<Failure, Paginator<Deal>>> call(GetDealsParams params) async {
    return mainRepository.getLostDeals(
      page: params.page,
      perPage: params.perPage,
    );
  }
}

import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/services/paginator/paginator.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/main/domain/entities/deal_message.dart';
import 'package:alma_desktop/features/main/domain/repositories/main_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class GetDealMessagesUseCase
    implements UseCase<Paginator<DealMessage>, GetDealMessagesParams> {
  final MainRepository mainRepository;

  GetDealMessagesUseCase({required this.mainRepository});

  @override
  Future<Either<Failure, Paginator<DealMessage>>> call(
    GetDealMessagesParams params,
  ) async {
    return mainRepository.getDealMessages(
      params.dealId,
      page: params.page,
      perPage: params.perPage,
    );
  }
}

class GetDealMessagesParams extends Equatable {
  final int dealId;
  final int page;
  final int perPage;

  const GetDealMessagesParams({
    required this.dealId,
    this.page = 1,
    this.perPage = 50,
  });

  @override
  List<Object?> get props => [dealId, page, perPage];
}

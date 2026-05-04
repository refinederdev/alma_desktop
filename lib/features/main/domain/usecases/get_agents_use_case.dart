import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/main/domain/entities/agent.dart';
import 'package:alma_desktop/features/main/domain/repositories/main_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class GetAgentsUseCase implements UseCase<List<Agent>, GetAgentsParams> {
  final MainRepository mainRepository;

  GetAgentsUseCase({required this.mainRepository});

  @override
  Future<Either<Failure, List<Agent>>> call(GetAgentsParams params) async {
    return mainRepository.getAgents(search: params.search);
  }
}

class GetAgentsParams extends Equatable {
  final String? search;

  const GetAgentsParams({this.search});

  @override
  List<Object?> get props => [search];
}

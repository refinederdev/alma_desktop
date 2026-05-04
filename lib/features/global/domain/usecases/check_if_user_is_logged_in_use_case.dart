import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/global/domain/entities/check_auth.dart';
import 'package:alma_desktop/features/global/domain/repositories/global_repository.dart';
import 'package:dartz/dartz.dart';

class CheckIfUserIsLoggedInUseCase implements UseCase<CheckAuth, NoParams> {
  final GlobalRepository globalRepository;

  CheckIfUserIsLoggedInUseCase({required this.globalRepository});

  @override
  Future<Either<Failure, CheckAuth>> call(NoParams params) async {
    return globalRepository.checkIfUserIsLoggedIn();
  }
}

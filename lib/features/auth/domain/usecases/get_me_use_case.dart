import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/auth/domain/entities/user.dart';
import 'package:alma_desktop/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';

class GetMeUseCase implements UseCase<User, NoParams> {
  final AuthRepository authRepository;

  GetMeUseCase({required this.authRepository});

  @override
  Future<Either<Failure, User>> call(NoParams params) async {
    return authRepository.getMe();
  }
}

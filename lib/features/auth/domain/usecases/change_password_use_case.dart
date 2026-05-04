import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class ChangePasswordUseCase implements UseCase<String, ChangePasswordParams> {
  final AuthRepository authRepository;

  ChangePasswordUseCase({required this.authRepository});

  @override
  Future<Either<Failure, String>> call(ChangePasswordParams params) async {
    return authRepository.changePassword(
      currentPassword: params.currentPassword,
      password: params.password,
      passwordConfirmation: params.passwordConfirmation,
    );
  }
}

class ChangePasswordParams extends Equatable {
  final String currentPassword;
  final String password;
  final String passwordConfirmation;

  const ChangePasswordParams({
    required this.currentPassword,
    required this.password,
    required this.passwordConfirmation,
  });

  @override
  List<Object?> get props => [currentPassword, password, passwordConfirmation];
}

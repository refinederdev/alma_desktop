import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class ResetPasswordUseCase implements UseCase<String, ResetPasswordParams> {
  final AuthRepository authRepository;

  ResetPasswordUseCase({required this.authRepository});

  @override
  Future<Either<Failure, String>> call(ResetPasswordParams params) async {
    return authRepository.resetPassword(
      resetToken: params.resetToken,
      password: params.password,
      passwordConfirmation: params.passwordConfirmation,
    );
  }
}

class ResetPasswordParams extends Equatable {
  final String resetToken;
  final String password;
  final String passwordConfirmation;

  const ResetPasswordParams({
    required this.resetToken,
    required this.password,
    required this.passwordConfirmation,
  });

  @override
  List<Object?> get props => [resetToken, password, passwordConfirmation];
}

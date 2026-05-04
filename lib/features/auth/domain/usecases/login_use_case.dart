import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/auth/domain/entities/login_response.dart';
import 'package:alma_desktop/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class LoginUseCase implements UseCase<LoginResponse, LoginParams> {
  final AuthRepository authRepository;

  LoginUseCase({required this.authRepository});

  @override
  Future<Either<Failure, LoginResponse>> call(LoginParams params) async {
    return authRepository.login(
      phone: params.phone,
      email: params.email,
      password: params.password,
    );
  }
}

class LoginParams extends Equatable {
  final String password;
  final String? phone;
  final String? email;

  const LoginParams({
    required this.password,
    this.phone,
    this.email,
  }) : assert(
          (phone != null && email == null) || (phone == null && email != null),
        );

  @override
  List<Object?> get props => [phone, email, password];
}

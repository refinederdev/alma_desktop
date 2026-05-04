import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class ForgetPasswordUseCase implements UseCase<String, ForgetPasswordParams> {
  final AuthRepository authRepository;

  ForgetPasswordUseCase({required this.authRepository});

  @override
  Future<Either<Failure, String>> call(ForgetPasswordParams params) async {
    return authRepository.forgetPassword(phone: params.phone);
  }
}

class ForgetPasswordParams extends Equatable {
  final String phone;

  const ForgetPasswordParams({required this.phone});

  @override
  List<Object?> get props => [phone];
}

import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/auth/domain/entities/validate_otp_response.dart';
import 'package:alma_desktop/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class ValidateOtpUseCase
    implements UseCase<ValidateOtpResponse, ValidateOtpParams> {
  final AuthRepository authRepository;

  ValidateOtpUseCase({required this.authRepository});

  @override
  Future<Either<Failure, ValidateOtpResponse>> call(
    ValidateOtpParams params,
  ) async {
    return authRepository.validateOtp(phone: params.phone, otp: params.otp);
  }
}

class ValidateOtpParams extends Equatable {
  final String phone;
  final String otp;

  const ValidateOtpParams({required this.phone, required this.otp});

  @override
  List<Object?> get props => [phone, otp];
}

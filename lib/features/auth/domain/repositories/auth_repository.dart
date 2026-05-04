import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/features/auth/domain/entities/login_response.dart';
import 'package:alma_desktop/features/auth/domain/entities/user.dart';
import 'package:alma_desktop/features/auth/domain/entities/validate_otp_response.dart';
import 'package:dartz/dartz.dart';

abstract class AuthRepository {
  Future<Either<Failure, LoginResponse>> login({
    required String password,
    String? phone,
    String? email,
  });

  Future<Either<Failure, String>> forgetPassword({required String phone});

  Future<Either<Failure, ValidateOtpResponse>> validateOtp({
    required String phone,
    required String otp,
  });

  Future<Either<Failure, String>> resetPassword({
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  });

  Future<Either<Failure, User>> getMe();

  Future<Either<Failure, User>> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? language,
    String? avatar,
  });

  Future<Either<Failure, String>> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  });
}

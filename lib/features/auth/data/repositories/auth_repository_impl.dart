import 'package:alma_desktop/core/errors/exceptions.dart';
import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:alma_desktop/features/auth/data/datasources/auth_remote_data_soruce.dart';
import 'package:alma_desktop/features/auth/domain/entities/login_response.dart';
import 'package:alma_desktop/features/auth/domain/entities/user.dart';
import 'package:alma_desktop/features/auth/domain/entities/validate_otp_response.dart';
import 'package:alma_desktop/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';

class AuthRepositoryImpl extends AuthRepository {
  final AuthRemoteDataSource authRemoteDataSource;
  final AuthLocalDataSource authLocalDataSource;
  AuthRepositoryImpl({
    required this.authRemoteDataSource,
    required this.authLocalDataSource,
  });

  @override
  Future<Either<Failure, LoginResponse>> login({
    required String password,
    String? phone,
    String? email,
  }) async {
    try {
      final result = await authRemoteDataSource.login(
        phone: phone,
        email: email,
        password: password,
      );
      await authLocalDataSource.saveAccessToken(result.accessToken);
      await authLocalDataSource.saveUser(result.user);
      return Right(result);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> forgetPassword({
    required String phone,
  }) async {
    try {
      final result = await authRemoteDataSource.forgetPassword(phone: phone);
      return Right(result);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message.toString()));
    }
  }

  @override
  Future<Either<Failure, ValidateOtpResponse>> validateOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final result = await authRemoteDataSource.validateOtp(
        phone: phone,
        otp: otp,
      );
      return Right(result);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> resetPassword({
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final result = await authRemoteDataSource.resetPassword(
        resetToken: resetToken,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      return Right(result);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getMe() async {
    try {
      final result = await authRemoteDataSource.getMe();
      return Right(result);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? language,
    String? avatar,
  }) async {
    try {
      final result = await authRemoteDataSource.updateProfile(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        language: language,
        avatar: avatar,
      );
      // حفظ المستخدم المحدث في local storage
      await authLocalDataSource.saveUser(result);
      return Right(result);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final result = await authRemoteDataSource.changePassword(
        currentPassword: currentPassword,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      return Right(result);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.message.toString()));
    }
  }
}

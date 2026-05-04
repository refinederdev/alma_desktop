import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/auth/domain/entities/user.dart';
import 'package:alma_desktop/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class UpdateProfileUseCase implements UseCase<User, UpdateProfileParams> {
  final AuthRepository authRepository;

  UpdateProfileUseCase({required this.authRepository});

  @override
  Future<Either<Failure, User>> call(UpdateProfileParams params) async {
    return authRepository.updateProfile(
      firstName: params.firstName,
      lastName: params.lastName,
      email: params.email,
      phone: params.phone,
      language: params.language,
      avatar: params.avatar,
    );
  }
}

class UpdateProfileParams extends Equatable {
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? language;
  final String? avatar;

  const UpdateProfileParams({
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.language,
    this.avatar,
  });

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    email,
    phone,
    language,
    avatar,
  ];
}

import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/features/global/domain/entities/check_auth.dart';
import 'package:dartz/dartz.dart';

abstract class GlobalRepository {
  Future<Either<Failure, CheckAuth>> checkIfUserIsLoggedIn();
}

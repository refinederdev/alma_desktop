import 'package:alma_desktop/core/errors/exceptions.dart';
import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/features/global/data/datasources/global_local_data_source.dart';
import 'package:alma_desktop/features/global/domain/entities/check_auth.dart';
import 'package:alma_desktop/features/global/domain/repositories/global_repository.dart';
import 'package:dartz/dartz.dart';

class GlobalRepositoryImpl extends GlobalRepository {
  final GlobalLocalDataSource globalLocalDataSource;

  GlobalRepositoryImpl({required this.globalLocalDataSource});

  @override
  Future<Either<Failure, CheckAuth>> checkIfUserIsLoggedIn() async {
    try {
      final result = await globalLocalDataSource.getCheckAuth();
      if (result == null) {
        return Left(ServerFailure(message: 'No token found'));
      }
      return Right(result);
    } on CustomException catch (e) {
      return Left(ServerFailure(exception: e, message: e.toString()));
    }
  }
}

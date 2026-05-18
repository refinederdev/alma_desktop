import 'package:alma_desktop/core/errors/exceptions.dart';
import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/services/paginator/paginator.dart';
import 'package:alma_desktop/features/calls/data/datasources/calls_remote_data_source.dart';
import 'package:alma_desktop/features/calls/domain/entities/call_permission.dart';
import 'package:alma_desktop/features/calls/domain/entities/call_sessions_response.dart';
import 'package:alma_desktop/features/calls/domain/entities/whatsapp_call.dart';
import 'package:alma_desktop/features/calls/domain/repositories/calls_repository.dart';
import 'package:dartz/dartz.dart';

class CallsRepositoryImpl implements CallsRepository {
  final CallsRemoteDataSource remoteDataSource;

  CallsRepositoryImpl({required this.remoteDataSource});

  Either<Failure, T> _wrapError<T>(CustomException e) {
    return Left(ServerFailure(exception: e, message: e.message));
  }

  @override
  Future<Either<Failure, CallSessionsResponse>> getSessions() async {
    try {
      final r = await remoteDataSource.getSessions();
      return Right(r);
    } on CustomException catch (e) {
      return _wrapError(e);
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> setCallingEnabled(
    int sessionId, {
    required bool enabled,
  }) async {
    try {
      final r = await remoteDataSource.setCallingEnabled(
        sessionId,
        enabled: enabled,
      );
      return Right(r);
    } on CustomException catch (e) {
      return _wrapError(e);
    }
  }

  @override
  Future<Either<Failure, WhatsAppCall?>> getActiveCall(int sessionId) async {
    try {
      final r = await remoteDataSource.getActiveCall(sessionId);
      return Right(r);
    } on CustomException catch (e) {
      return _wrapError(e);
    }
  }

  @override
  Future<Either<Failure, WhatsAppCall>> getCallById(
    int callId, {
    bool includeSdp = false,
  }) async {
    try {
      final r = await remoteDataSource.getCallById(
        callId,
        includeSdp: includeSdp,
      );
      return Right(r);
    } on CustomException catch (e) {
      return _wrapError(e);
    }
  }

  @override
  Future<Either<Failure, WhatsAppCall>> getCallSdp(int callId) async {
    try {
      final r = await remoteDataSource.getCallSdp(callId);
      return Right(r);
    } on CustomException catch (e) {
      return _wrapError(e);
    }
  }

  @override
  Future<Either<Failure, Paginator<WhatsAppCall>>> getCallHistory({
    required int sessionId,
    int page = 1,
    int perPage = 20,
    String? direction,
    String? status,
    int? dealId,
  }) async {
    try {
      final r = await remoteDataSource.getCallHistory(
        sessionId: sessionId,
        page: page,
        perPage: perPage,
        direction: direction,
        status: status,
        dealId: dealId,
      );
      final p = Paginator<WhatsAppCall>(
        data: List<WhatsAppCall>.from(r.data),
        currentPage: r.currentPage,
        perPage: r.perPage,
        total: r.total,
        lastPage: r.lastPage,
        from: r.from,
        to: r.to,
        hasMorePages: r.hasMorePages,
        meta: r.meta,
      );
      return Right(p);
    } on CustomException catch (e) {
      return _wrapError(e);
    }
  }

  @override
  Future<Either<Failure, WhatsAppCall>> initiateCall({
    required int sessionId,
    required String to,
    required String sdpOffer,
  }) async {
    try {
      final r = await remoteDataSource.initiateCall(
        sessionId: sessionId,
        to: to,
        sdpOffer: sdpOffer,
      );
      return Right(r);
    } on CustomException catch (e) {
      return _wrapError(e);
    }
  }

  @override
  Future<Either<Failure, WhatsAppCall>> acceptCall({
    required int callId,
    required String sdpAnswer,
  }) async {
    try {
      final r = await remoteDataSource.acceptCall(
        callId: callId,
        sdpAnswer: sdpAnswer,
      );
      return Right(r);
    } on CustomException catch (e) {
      return _wrapError(e);
    }
  }

  @override
  Future<Either<Failure, WhatsAppCall>> preAcceptCall({
    required int callId,
    required String sdpAnswer,
  }) async {
    try {
      final r = await remoteDataSource.preAcceptCall(
        callId: callId,
        sdpAnswer: sdpAnswer,
      );
      return Right(r);
    } on CustomException catch (e) {
      return _wrapError(e);
    }
  }

  @override
  Future<Either<Failure, WhatsAppCall>> rejectCall(int callId) async {
    try {
      final r = await remoteDataSource.rejectCall(callId);
      return Right(r);
    } on CustomException catch (e) {
      return _wrapError(e);
    }
  }

  @override
  Future<Either<Failure, WhatsAppCall>> terminateCall(int callId) async {
    try {
      final r = await remoteDataSource.terminateCall(callId);
      return Right(r);
    } on CustomException catch (e) {
      return _wrapError(e);
    }
  }

  @override
  Future<Either<Failure, CallPermission>> checkPermission({
    required int sessionId,
    required String userPhone,
  }) async {
    try {
      final r = await remoteDataSource.checkPermission(
        sessionId: sessionId,
        userPhone: userPhone,
      );
      return Right(r);
    } on CustomException catch (e) {
      return _wrapError(e);
    }
  }

  @override
  Future<Either<Failure, CallPermission>> requestPermission({
    required int sessionId,
    required String to,
    String? templateName,
    String? languageCode,
  }) async {
    try {
      final r = await remoteDataSource.requestPermission(
        sessionId: sessionId,
        to: to,
        templateName: templateName,
        languageCode: languageCode,
      );
      return Right(r);
    } on CustomException catch (e) {
      return _wrapError(e);
    }
  }
}

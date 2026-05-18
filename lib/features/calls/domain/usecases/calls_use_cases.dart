import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/services/paginator/paginator.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/calls/domain/entities/call_permission.dart';
import 'package:alma_desktop/features/calls/domain/entities/call_sessions_response.dart';
import 'package:alma_desktop/features/calls/domain/entities/whatsapp_call.dart';
import 'package:alma_desktop/features/calls/domain/repositories/calls_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class GetCallSessionsUseCase implements UseCase<CallSessionsResponse, NoParams> {
  final CallsRepository repository;

  GetCallSessionsUseCase({required this.repository});

  @override
  Future<Either<Failure, CallSessionsResponse>> call(NoParams params) {
    return repository.getSessions();
  }
}

class GetActiveCallUseCase implements UseCase<WhatsAppCall?, int> {
  final CallsRepository repository;

  GetActiveCallUseCase({required this.repository});

  @override
  Future<Either<Failure, WhatsAppCall?>> call(int sessionId) {
    return repository.getActiveCall(sessionId);
  }
}

class GetCallSdpUseCase implements UseCase<WhatsAppCall, int> {
  final CallsRepository repository;

  GetCallSdpUseCase({required this.repository});

  @override
  Future<Either<Failure, WhatsAppCall>> call(int callId) {
    return repository.getCallSdp(callId);
  }
}

class InitiateCallUseCase implements UseCase<WhatsAppCall, InitiateCallParams> {
  final CallsRepository repository;

  InitiateCallUseCase({required this.repository});

  @override
  Future<Either<Failure, WhatsAppCall>> call(InitiateCallParams params) {
    return repository.initiateCall(
      sessionId: params.sessionId,
      to: params.to,
      sdpOffer: params.sdpOffer,
    );
  }
}

class InitiateCallParams extends Equatable {
  final int sessionId;
  final String to;
  final String sdpOffer;

  const InitiateCallParams({
    required this.sessionId,
    required this.to,
    required this.sdpOffer,
  });

  @override
  List<Object?> get props => [sessionId, to, sdpOffer];
}

class AcceptCallUseCase implements UseCase<WhatsAppCall, AcceptCallParams> {
  final CallsRepository repository;

  AcceptCallUseCase({required this.repository});

  @override
  Future<Either<Failure, WhatsAppCall>> call(AcceptCallParams params) {
    return repository.acceptCall(
      callId: params.callId,
      sdpAnswer: params.sdpAnswer,
    );
  }
}

class AcceptCallParams extends Equatable {
  final int callId;
  final String sdpAnswer;

  const AcceptCallParams({required this.callId, required this.sdpAnswer});

  @override
  List<Object?> get props => [callId, sdpAnswer];
}

class RejectCallUseCase implements UseCase<WhatsAppCall, int> {
  final CallsRepository repository;

  RejectCallUseCase({required this.repository});

  @override
  Future<Either<Failure, WhatsAppCall>> call(int callId) {
    return repository.rejectCall(callId);
  }
}

class TerminateCallUseCase implements UseCase<WhatsAppCall, int> {
  final CallsRepository repository;

  TerminateCallUseCase({required this.repository});

  @override
  Future<Either<Failure, WhatsAppCall>> call(int callId) {
    return repository.terminateCall(callId);
  }
}

class GetCallHistoryUseCase
    implements UseCase<Paginator<WhatsAppCall>, GetCallHistoryParams> {
  final CallsRepository repository;

  GetCallHistoryUseCase({required this.repository});

  @override
  Future<Either<Failure, Paginator<WhatsAppCall>>> call(
    GetCallHistoryParams params,
  ) {
    return repository.getCallHistory(
      sessionId: params.sessionId,
      page: params.page,
      perPage: params.perPage,
      direction: params.direction,
      status: params.status,
      dealId: params.dealId,
    );
  }
}

class GetCallHistoryParams extends Equatable {
  final int sessionId;
  final int page;
  final int perPage;
  final String? direction;
  final String? status;
  final int? dealId;

  const GetCallHistoryParams({
    required this.sessionId,
    this.page = 1,
    this.perPage = 20,
    this.direction,
    this.status,
    this.dealId,
  });

  @override
  List<Object?> get props => [sessionId, page, perPage, direction, status, dealId];
}

class CheckCallPermissionUseCase
    implements UseCase<CallPermission, CheckCallPermissionParams> {
  final CallsRepository repository;

  CheckCallPermissionUseCase({required this.repository});

  @override
  Future<Either<Failure, CallPermission>> call(
    CheckCallPermissionParams params,
  ) {
    return repository.checkPermission(
      sessionId: params.sessionId,
      userPhone: params.userPhone,
    );
  }
}

class CheckCallPermissionParams extends Equatable {
  final int sessionId;
  final String userPhone;

  const CheckCallPermissionParams({
    required this.sessionId,
    required this.userPhone,
  });

  @override
  List<Object?> get props => [sessionId, userPhone];
}

class RequestCallPermissionUseCase
    implements UseCase<CallPermission, RequestCallPermissionParams> {
  final CallsRepository repository;

  RequestCallPermissionUseCase({required this.repository});

  @override
  Future<Either<Failure, CallPermission>> call(
    RequestCallPermissionParams params,
  ) {
    return repository.requestPermission(
      sessionId: params.sessionId,
      to: params.to,
      templateName: params.templateName,
      languageCode: params.languageCode,
    );
  }
}

class RequestCallPermissionParams extends Equatable {
  final int sessionId;
  final String to;
  final String? templateName;
  final String? languageCode;

  const RequestCallPermissionParams({
    required this.sessionId,
    required this.to,
    this.templateName,
    this.languageCode,
  });

  @override
  List<Object?> get props => [sessionId, to, templateName, languageCode];
}

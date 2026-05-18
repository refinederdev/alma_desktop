import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/services/paginator/paginator.dart';
import 'package:alma_desktop/features/calls/domain/entities/call_permission.dart';
import 'package:alma_desktop/features/calls/domain/entities/call_sessions_response.dart';
import 'package:alma_desktop/features/calls/domain/entities/whatsapp_call.dart';
import 'package:dartz/dartz.dart';

abstract class CallsRepository {
  Future<Either<Failure, CallSessionsResponse>> getSessions();

  Future<Either<Failure, Map<String, dynamic>>> setCallingEnabled(
    int sessionId, {
    required bool enabled,
  });

  Future<Either<Failure, WhatsAppCall?>> getActiveCall(int sessionId);

  Future<Either<Failure, WhatsAppCall>> getCallById(
    int callId, {
    bool includeSdp = false,
  });

  Future<Either<Failure, WhatsAppCall>> getCallSdp(int callId);

  Future<Either<Failure, Paginator<WhatsAppCall>>> getCallHistory({
    required int sessionId,
    int page = 1,
    int perPage = 20,
    String? direction,
    String? status,
    int? dealId,
  });

  Future<Either<Failure, WhatsAppCall>> initiateCall({
    required int sessionId,
    required String to,
    required String sdpOffer,
  });

  Future<Either<Failure, WhatsAppCall>> acceptCall({
    required int callId,
    required String sdpAnswer,
  });

  Future<Either<Failure, WhatsAppCall>> preAcceptCall({
    required int callId,
    required String sdpAnswer,
  });

  Future<Either<Failure, WhatsAppCall>> rejectCall(int callId);

  Future<Either<Failure, WhatsAppCall>> terminateCall(int callId);

  Future<Either<Failure, CallPermission>> checkPermission({
    required int sessionId,
    required String userPhone,
  });

  Future<Either<Failure, CallPermission>> requestPermission({
    required int sessionId,
    required String to,
    String? templateName,
    String? languageCode,
  });
}

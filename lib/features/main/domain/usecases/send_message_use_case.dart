import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/main/domain/entities/deal_message.dart';
import 'package:alma_desktop/features/main/domain/repositories/main_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class SendMessageUseCase implements UseCase<DealMessage, SendMessageParams> {
  final MainRepository mainRepository;

  SendMessageUseCase({required this.mainRepository});

  @override
  Future<Either<Failure, DealMessage>> call(SendMessageParams params) async {
    return mainRepository.sendMessage(
      dealId: params.dealId,
      messageBody: params.messageBody,
      messageType: params.messageType,
      fromMe: params.fromMe,
      mediaPath: params.mediaPath,
      locationId: params.locationId,
    );
  }
}

class SendMessageParams extends Equatable {
  final int dealId;
  final String? messageBody;
  final String? messageType;
  final bool fromMe;
  final String? mediaPath;
  final int? locationId;

  const SendMessageParams({
    required this.dealId,
    this.messageBody,
    this.messageType,
    required this.fromMe,
    this.mediaPath,
    this.locationId,
  });

  @override
  List<Object?> get props => [
    dealId,
    messageBody,
    messageType,
    fromMe,
    mediaPath,
    locationId,
  ];
}

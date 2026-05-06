import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/main/domain/entities/deal_message.dart';
import 'package:alma_desktop/features/main/domain/repositories/main_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class UpdateMessageUseCase
    implements UseCase<DealMessage, UpdateMessageParams> {
  final MainRepository mainRepository;

  UpdateMessageUseCase({required this.mainRepository});

  @override
  Future<Either<Failure, DealMessage>> call(UpdateMessageParams params) async {
    return mainRepository.updateMessage(
      messageId: params.messageId,
      messageBody: params.messageBody,
      mediaUrl: params.mediaUrl,
      mediaType: params.mediaType,
    );
  }
}

class UpdateMessageParams extends Equatable {
  final int messageId;
  final String? messageBody;
  final String? mediaUrl;
  final String? mediaType;

  const UpdateMessageParams({
    required this.messageId,
    this.messageBody,
    this.mediaUrl,
    this.mediaType,
  });

  @override
  List<Object?> get props => [messageId, messageBody, mediaUrl, mediaType];
}

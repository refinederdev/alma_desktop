import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/main/domain/repositories/main_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class DeleteMessageUseCase implements UseCase<void, DeleteMessageParams> {
  final MainRepository mainRepository;

  DeleteMessageUseCase({required this.mainRepository});

  @override
  Future<Either<Failure, void>> call(DeleteMessageParams params) async {
    return mainRepository.deleteMessage(messageId: params.messageId);
  }
}

class DeleteMessageParams extends Equatable {
  final int messageId;

  const DeleteMessageParams({required this.messageId});

  @override
  List<Object?> get props => [messageId];
}

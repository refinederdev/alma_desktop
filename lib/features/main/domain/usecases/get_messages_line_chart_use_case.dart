import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/main/domain/entities/message_line_chart_data.dart';
import 'package:alma_desktop/features/main/domain/repositories/main_repository.dart';
import 'package:dartz/dartz.dart';

class GetMessagesLineChartUseCase
    implements UseCase<List<MessageLineChartData>, NoParams> {
  final MainRepository mainRepository;

  GetMessagesLineChartUseCase({required this.mainRepository});

  @override
  Future<Either<Failure, List<MessageLineChartData>>> call(
    NoParams params,
  ) async {
    return mainRepository.getMessagesLineChart();
  }
}

import 'package:equatable/equatable.dart';

class DealStats extends Equatable {
  final int totalCount;
  final int openCount;
  final int wonCount;
  final int lostCount;

  const DealStats({
    required this.totalCount,
    required this.openCount,
    required this.wonCount,
    required this.lostCount,
  });

  @override
  List<Object?> get props => [totalCount, openCount, wonCount, lostCount];
}

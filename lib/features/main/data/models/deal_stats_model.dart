import 'package:alma_desktop/features/main/domain/entities/deal_stats.dart';

class DealStatsModel extends DealStats {
  const DealStatsModel({
    required super.totalCount,
    required super.openCount,
    required super.wonCount,
    required super.lostCount,
  }) : super();

  factory DealStatsModel.fromJson(Map<String, dynamic> json) => DealStatsModel(
    totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
    openCount: (json['open_count'] as num?)?.toInt() ?? 0,
    wonCount: (json['won_count'] as num?)?.toInt() ?? 0,
    lostCount: (json['lost_count'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'total_count': totalCount,
    'open_count': openCount,
    'won_count': wonCount,
    'lost_count': lostCount,
  };
}

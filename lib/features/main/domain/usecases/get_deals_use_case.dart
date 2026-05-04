import 'package:equatable/equatable.dart';

class GetDealsParams extends Equatable {
  final int page;
  final int perPage;

  const GetDealsParams({this.page = 1, this.perPage = 15});

  @override
  List<Object?> get props => [page, perPage];
}

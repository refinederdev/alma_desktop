import 'package:equatable/equatable.dart';

/// Domain-level paginator holding list of items and pagination meta.
class Paginator<T> extends Equatable {
  final List<T> data;
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;
  final int? from;
  final int? to;
  final bool hasMorePages;
  final Map<String, dynamic>? meta;

  const Paginator({
    required this.data,
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
    this.from,
    this.to,
    required this.hasMorePages,
    this.meta,
  });

  @override
  List<Object?> get props => [
        data,
        currentPage,
        perPage,
        total,
        lastPage,
        from,
        to,
        hasMorePages,
        meta,
      ];
}

/// Data-layer paginator with JSON parsing. Parses API response that contains
/// `data` (list) and `pagination` (meta).
class PaginatorModel<T> extends Paginator<T> {
  const PaginatorModel({
    required super.data,
    required super.currentPage,
    required super.perPage,
    required super.total,
    required super.lastPage,
    super.from,
    super.to,
    required super.hasMorePages,
    super.meta,
  });

  factory PaginatorModel.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final list = json['data'] as List<dynamic>? ?? [];
    final data = list
        .map((e) => fromJsonT(e as Map<String, dynamic>))
        .toList();

    final p = json['pagination'] as Map<String, dynamic>? ?? {};
    return PaginatorModel<T>(
      data: data,
      currentPage: p['current_page'] as int? ?? 1,
      perPage: p['per_page'] as int? ?? 15,
      total: p['total'] as int? ?? 0,
      lastPage: p['last_page'] as int? ?? 1,
      from: p['from'] as int?,
      to: p['to'] as int?,
      hasMorePages: p['has_more_pages'] as bool? ?? false,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }
}

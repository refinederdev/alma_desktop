/// نموذج الاستجابة من API يتوافق مع هيكل Backend
/// 
/// هيكل الاستجابة الناجحة:
/// {
///   "success": true,
///   "status_code": "SUCCESS",
///   "message": "...",
///   "data": {...},
///   "meta": {...} // اختياري
/// }
/// 
/// هيكل الاستجابة مع Pagination:
/// {
///   "success": true,
///   "status_code": "SUCCESS",
///   "message": "...",
///   "data": [...],
///   "pagination": {
///     "current_page": 1,
///     "per_page": 10,
///     "total": 100,
///     "last_page": 10,
///     "from": 1,
///     "to": 10,
///     "has_more_pages": true
///   }
/// }
/// 
/// هيكل الاستجابة مع خطأ:
/// {
///   "success": false,
///   "status_code": "ERROR" | "VALIDATION_ERROR" | "UNAUTHORIZED" | etc,
///   "message": "...",
///   "errors": {...} // اختياري
///   "meta": {...} // اختياري
/// }
class ApiResponseModel<T> {
  final bool success;
  final String statusCode;
  final String message;
  final T? data;
  final Map<String, dynamic>? errors;
  final PaginationModel? pagination;
  final Map<String, dynamic>? meta;

  ApiResponseModel({
    required this.success,
    required this.statusCode,
    required this.message,
    this.data,
    this.errors,
    this.pagination,
    this.meta,
  });

  factory ApiResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponseModel<T>(
      success: json['success'] as bool? ?? false,
      statusCode: json['status_code'] as String? ?? 'ERROR',
      message: json['message'] as String? ?? '',
      data: json['data'] != null
          ? (fromJsonT != null
              ? fromJsonT(json['data'])
              : json['data'] as T?)
          : null,
      errors: json['errors'] as Map<String, dynamic>?,
      pagination: json['pagination'] != null
          ? PaginationModel.fromJson(
              json['pagination'] as Map<String, dynamic>)
          : null,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'status_code': statusCode,
      'message': message,
      if (data != null) 'data': data,
      if (errors != null) 'errors': errors,
      if (pagination != null) 'pagination': pagination?.toJson(),
      if (meta != null) 'meta': meta,
    };
  }
}

/// نموذج Pagination يتوافق مع Backend
class PaginationModel {
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;
  final int? from;
  final int? to;
  final bool hasMorePages;

  PaginationModel({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
    this.from,
    this.to,
    required this.hasMorePages,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      currentPage: json['current_page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 10,
      total: json['total'] as int? ?? 0,
      lastPage: json['last_page'] as int? ?? 1,
      from: json['from'] as int?,
      to: json['to'] as int?,
      hasMorePages: json['has_more_pages'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'per_page': perPage,
      'total': total,
      'last_page': lastPage,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      'has_more_pages': hasMorePages,
    };
  }
}

class CustomException implements Exception {
  final int? code;
  final String message;

  CustomException({this.code, required this.message});
}

class UnAuthorizedException implements CustomException {
  @override
  final String message;
  @override
  final int? code;

  UnAuthorizedException(this.message, {this.code});
}

class ValidationException implements CustomException {
  @override
  final String message;
  @override
  final int? code;
  final Map<String, dynamic>? error;
  ValidationException(this.message, {this.error, this.code});
}

class BadRequestException implements CustomException {
  @override
  final String message;
  @override
  final int? code;
  BadRequestException(this.message, {this.code});
}

class RequestTimeoutException implements CustomException {
  @override
  final String message;
  @override
  final int? code;
  RequestTimeoutException(this.message, {this.code});
}

class ServerException implements CustomException {
  @override
  final String message;
  @override
  final int? code;
  ServerException(this.message, {this.code});
}

class TooManyAttemptsException implements CustomException {
  @override
  final String message;
  @override
  final int? code;
  TooManyAttemptsException(this.message, {this.code});
}

class NoInternetException implements CustomException {
  @override
  final String message;
  @override
  final int? code;

  NoInternetException(this.message, {this.code});
}

class ForbiddenException implements CustomException {
  @override
  final String message;
  @override
  final int? code;

  ForbiddenException(this.message, {this.code});
}

class NotFoundException implements CustomException {
  @override
  final String message;
  @override
  final int? code;

  NotFoundException(this.message, {this.code});
}

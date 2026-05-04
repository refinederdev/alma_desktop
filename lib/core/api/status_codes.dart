class StatusCode {
  // HTTP Success Status Codes
  static const int ok = 200;
  static const int created = 201;
  static const int accepted = 202;
  static const int noContent = 204;

  // HTTP Client Error Status Codes
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int methodNotAllowed = 405;
  static const int conflict = 409;
  static const int validationError = 422;
  static const int tooManyAttempts = 429;

  // HTTP Server Error Status Codes
  static const int internalServerError = 500;
  static const int badGateway = 502;
  static const int serviceUnavailable = 503;

  // Custom API Response Codes (from Backend)
  static const String success = 'SUCCESS';
  static const String error = 'ERROR';
  static const String validationErrorCode = 'VALIDATION_ERROR';
  static const String unauthorizedCode = 'UNAUTHORIZED';
  static const String forbiddenCode = 'FORBIDDEN';
  static const String notFoundCode = 'NOT_FOUND';
  static const String serverErrorCode = 'SERVER_ERROR';
  static const String rateLimitExceeded = 'RATE_LIMIT_EXCEEDED';
}

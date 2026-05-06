import 'dart:convert';
import 'dart:developer';
import 'package:alma_desktop/core/config/app_routes.dart';
// import 'package:alma_desktop/features/auth/presentation/controllers/login_controller.dart';
import 'package:alma_desktop/features/global/presentation/controllers/global_controller.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;
import '../errors/exceptions.dart';
import 'app_interceptors.dart';
import 'error_handler.dart';
import 'status_codes.dart';

import '../config/app_config.dart';
import 'api_consumer.dart';

class DioConsumer implements ApiConsumer {
  final Dio client;
  DioConsumer({required this.client}) {
    client.options
      ..responseType = ResponseType.plain
      ..connectTimeout = const Duration(seconds: 30)
      ..followRedirects = false
      ..receiveDataWhenStatusError = true
      // قبول جميع أكواد النجاح (200-299) و 204 (No Content)
      ..validateStatus = (status) {
        return status != null &&
            ((status >= 200 && status < 300) || status == 204);
      };
    // Add Interceptors
    // client.interceptors.add(LogInterceptor());
    // if (kDebugMode) {
    client.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );

    client.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
    // }
    client.interceptors.add(AppInterceptos());
  }

  @override
  Future get(String path, {Map<String, dynamic>? queryParameters}) async {
    final fullPath = AppConfig.baseURL;
    try {
      final response = await client.get(
        '$fullPath$path',
        queryParameters: queryParameters,
      );
      return _processResponse(response);
    } on DioException catch (e) {
      _handleDioExceptions(e);
    }
  }

  @override
  Future post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool? isFormData = false,
  }) async {
    final fullPath = AppConfig.baseURL;
    try {
      var response = await client.post(
        '$fullPath$path',
        data: isFormData != null && isFormData == true
            ? FormData.fromMap(body ?? {})
            : body,
        queryParameters: queryParameters,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      return _processResponse(response);
    } on DioException catch (e) {
      _handleDioExceptions(e);
    }
  }

  @override
  Future put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool? isFormData = false,
  }) async {
    final fullPath = AppConfig.baseURL;

    try {
      final response = await client.put(
        '$fullPath$path',
        data: isFormData != null && isFormData == true
            ? FormData.fromMap(body ?? {})
            : body,
        queryParameters: queryParameters,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      return _processResponse(response);
    } on DioException catch (e) {
      _handleDioExceptions(e);
    }
  }

  @override
  Future delete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    final fullPath = AppConfig.baseURL;

    try {
      final response = await client.delete(
        '$fullPath$path',
        data: body != null ? FormData.fromMap(body) : body,
        queryParameters: queryParameters,
      );
      return _processResponse(response);
    } on DioException catch (e) {
      _handleDioExceptions(e);
    }
  }

  _handleDioExceptions(DioException err) {
    switch (err.type) {
      case DioExceptionType.badResponse:
        // محاولة تحليل الاستجابة
        Map<String, dynamic>? response;
        try {
          if (err.response?.data != null) {
            final responseData = err.response!.data;
            if (responseData is String) {
              response = jsonDecode(responseData) as Map<String, dynamic>?;
            } else if (responseData is Map) {
              response = responseData as Map<String, dynamic>;
            }
          }
        } catch (e) {
          log("Error parsing response: $e");
        }

        // إذا كانت الاستجابة تحتوي على success: false، تم التعامل معها في _processResponse
        // لكن في حالة badResponse، قد لا تكون الاستجابة في النطاق الصحيح
        if (response != null &&
            response.containsKey('success') &&
            !response['success']) {
          // تم التعامل معها في _processResponse، لكن نتحقق مرة أخرى
          final statusCode = response['status_code'] as String?;
          final message = response['message'] as String? ?? 'حدث خطأ غير معروف';
          final errors = response['errors'] as Map<String, dynamic>?;

          switch (statusCode) {
            case StatusCode.unauthorizedCode:
              log("Error : This is the un authorized exception");
              log(getx.Get.currentRoute);
              if (!(getx.Get.currentRoute.compareTo(AppRoutes.login) == 0)) {
                GlobalController.to.clearLogedIn();
                getx.Get.toNamed(AppRoutes.login, preventDuplicates: true);
              }
              throw UnAuthorizedException(message);
            case StatusCode.validationErrorCode:
              throw ValidationException(
                _getMessageFromValidationError(response) ?? message,
                error: errors ?? _getValidationErrors(response),
                code: StatusCode.validationError,
              );
            case StatusCode.forbiddenCode:
              throw ForbiddenException(message);
            case StatusCode.notFoundCode:
              throw NotFoundException(message);
            case StatusCode.rateLimitExceeded:
              final retryAfter = response['meta']?['retry_after'] as int?;
              throw TooManyAttemptsException(message, code: retryAfter);
            default:
              throw BadRequestException(
                message,
                code: err.response?.statusCode,
              );
          }
        }

        // معالجة الأخطاء بناءً على HTTP status code
        switch (err.response?.statusCode) {
          case StatusCode.unauthorized:
            log("Error : This is the un authorized exception");
            log(getx.Get.currentRoute);
            if (!(getx.Get.currentRoute.compareTo(AppRoutes.login) == 0)) {
              GlobalController.to.clearLogedIn();
              getx.Get.toNamed(AppRoutes.login, preventDuplicates: true);
            }
            throw UnAuthorizedException(
              response?['message'] as String? ?? 'غير مصرح',
            );
          case StatusCode.validationError:
            throw ValidationException(
              _getMessageFromValidationError(response ?? {}) ?? "خطأ في التحقق",
              error: response != null ? _getValidationErrors(response) : null,
              code: StatusCode.validationError,
            );
          case StatusCode.badRequest:
            throw BadRequestException(
              _getMessageFromError(response ?? {}) ?? "طلب غير صحيح",
            );
          case StatusCode.notFound:
            throw NotFoundException(
              response?['message'] as String? ?? 'غير موجود',
            );
          case StatusCode.internalServerError:
          case StatusCode.badGateway:
          case StatusCode.serviceUnavailable:
            throw ServerException(
              response?['message'] as String? ?? 'خطأ في الخادم',
            );
          case StatusCode.forbidden:
            throw ForbiddenException(
              response?['message'] as String? ?? 'غير مسموح',
            );
          case StatusCode.tooManyAttempts:
            final retryAfter = response?['meta']?['retry_after'] as int?;
            throw TooManyAttemptsException(
              response?['message'] as String? ??
                  'عدد الطلبات تجاوز الحد المسموح',
              code: retryAfter,
            );
          default:
            throw BadRequestException(
              _getMessageFromError(response ?? {}) ?? "حدث خطأ غير معروف",
              code: err.response?.statusCode,
            );
        }
      case DioExceptionType.connectionTimeout:
        log("Connection Timeout Exception - Dio Consumer");
        throw RequestTimeoutException("request_timeout".tr);
      case DioExceptionType.unknown:
        throw NetworkErrorHandler.networkHandler(err);
      case DioExceptionType.connectionError:
        throw NoInternetException("${"no_internet_access".tr} ${err.error}");
      default:
        throw BadRequestException(
          "حدث خطأ غير معروف",
          code: err.response?.statusCode,
        );
    }
  }

  String? _getMessageFromError(response) {
    if (response.containsKey("message")) {
      if (response["message"] is List) {
        return response["message"][0];
      } else {
        return response["message"];
      }
    } else {
      return "Error";
    }
  }

  String? _getMessageFromValidationError(response) {
    if (response.containsKey("errors")) {
      String? message;
      var errors = response["errors"];
      // Displaying error messages
      errors.forEach((key, value) {
        if (value is List) {
          message = value[0];
        } else {
          message = value;
        }
      });
      return message.toString();
    } else {
      return "Validation Error";
    }
  }

  _getValidationErrors(response) {
    if (response.containsKey("errors")) {
      var errors = response["errors"];
      return errors;
    } else {
      return {};
    }
  }

  @override
  Future request(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool? isFormData = false,
    dynamic options,
  }) async {
    final fullPath = AppConfig.baseURL;

    try {
      final response = await client.request(
        '$fullPath$path',
        options: options,
        data: isFormData != null && isFormData == true
            ? FormData.fromMap(body ?? {})
            : body,
        queryParameters: queryParameters,
      );
      return _processResponse(response);
    } on DioException catch (e) {
      _handleDioExceptions(e);
    }
  }

  /// معالجة الاستجابة من API
  /// يتحقق من success ويستخرج data من الاستجابة
  dynamic _processResponse(Response response) {
    // إذا كان 204 No Content، لا يوجد body
    if (response.statusCode == StatusCode.noContent) {
      return null;
    }

    // تحويل الاستجابة إلى JSON
    final responseData = jsonDecode(response.data.toString());

    // التحقق من أن الاستجابة هي Map
    if (responseData is! Map<String, dynamic>) {
      return responseData;
    }

    // التحقق من حقل success
    final success = responseData['success'] as bool? ?? false;
    final statusCode = responseData['status_code'] as String?;

    // إذا كانت الاستجابة غير ناجحة، رمي استثناء
    if (!success) {
      final message = responseData['message'] as String? ?? 'حدث خطأ غير معروف';
      final errors = responseData['errors'] as Map<String, dynamic>?;

      // تحديد نوع الاستثناء بناءً على status_code
      switch (statusCode) {
        case StatusCode.unauthorizedCode:
          log("Error : This is the un authorized exception");
          log(getx.Get.currentRoute);
          if (!(getx.Get.currentRoute.compareTo(AppRoutes.login) == 0)) {
            GlobalController.to.clearLogedIn();
            getx.Get.toNamed(AppRoutes.login, preventDuplicates: true);
          }
          throw UnAuthorizedException(message);
        case StatusCode.validationErrorCode:
          throw ValidationException(
            _getMessageFromValidationError(responseData) ?? message,
            error: errors ?? _getValidationErrors(responseData),
            code: StatusCode.validationError,
          );
        case StatusCode.forbiddenCode:
          throw ForbiddenException(message);
        case StatusCode.notFoundCode:
          throw NotFoundException(message);
        case StatusCode.rateLimitExceeded:
          final retryAfter = responseData['meta']?['retry_after'] as int?;
          throw TooManyAttemptsException(message, code: retryAfter);
        default:
          throw BadRequestException(message, code: response.statusCode);
      }
    }

    // إرجاع data من الاستجابة
    // إذا كان هناك pagination، نرجع الاستجابة كاملة مع pagination
    if (responseData.containsKey('pagination')) {
      return responseData;
    }

    // إرجاع data فقط
    return responseData['data'] ?? responseData;
  }
}

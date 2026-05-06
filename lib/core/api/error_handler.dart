import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../errors/app_messages.dart';
import '../errors/exceptions.dart';
import '../errors/failures.dart';

class NetworkErrorHandler {
  static CustomException networkHandler(e) {
    log("This is socket exception from the network handler $e");
    final exception = "$e";

    // DioExceptionType.unknown on desktop is often SSL/TLS or low-level socket.
    if (e is DioException) {
      final rawError = e.error;
      final message = '${e.message ?? ''} ${rawError ?? ''}'.toLowerCase();

      if (rawError is HandshakeException ||
          message.contains('certificate_verify_failed') ||
          message.contains('handshake') ||
          message.contains('tls') ||
          message.contains('ssl')) {
        throw NoInternetException(
          'SSL/TLS connection failed. Check device date/time, antivirus/proxy HTTPS inspection, and trusted certificates.',
        );
      }

      if (rawError is SocketException ||
          rawError is HttpException ||
          message.contains('socketexception') ||
          message.contains('failed host lookup') ||
          message.contains('connection refused') ||
          message.contains('network is unreachable')) {
        throw NoInternetException("${"no_internet_access".tr} ${rawError ?? e.message ?? ''}");
      }
    }

    if (e is HandshakeException ||
        exception.toLowerCase().contains('certificate_verify_failed') ||
        exception.toLowerCase().contains('handshake') ||
        exception.toLowerCase().contains('tls') ||
        exception.toLowerCase().contains('ssl')) {
      throw NoInternetException(
        'SSL/TLS connection failed. Check device date/time, antivirus/proxy HTTPS inspection, and trusted certificates.',
      );
    }

    if (e is SocketException ||
        e is HttpException ||
        exception.contains("HttpException") ||
        exception.contains("SocketException")) {
      throw NoInternetException("${"no_internet_access".tr} $e");
    }

    throw RequestTimeoutException("unknown_error".tr);
  }

  static Future<void> retryRequestWhenTimeout({
    Failure? failure,
    callBack,
    bool showMessage = false,
  }) async {
    if (failure?.exception is RequestTimeoutException) {
      if (showMessage) {
        AppMessages.showSnackBar(
          type: ErrorType.warning,
          title: "request_timeout".tr,
          duration: 4,
          message: "time_out_message".tr,
        );
      }
      await callBack();
    } else {
      if (showMessage) {
        AppMessages.showSnackBar(
          type: ErrorType.error,
          title: "error".tr,
          duration: 4,
          message: failure?.message ?? "error".tr,
        );
      }
    }
  }
}

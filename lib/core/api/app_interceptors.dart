import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:alma_desktop/features/global/presentation/controllers/global_controller.dart';
import '../config/app_config.dart';

class AppInterceptos implements Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // if (getx.Get.isSnackbarOpen) {
    //   getx.Get.closeAllSnackbars();
    // }
    if (!options.headers.containsKey('Content-Type')) {
      options.headers['Content-Type'] = options.data is FormData
          ? Headers.multipartFormDataContentType
          : Headers.jsonContentType;
    }

    options.headers.addAll({
      if (GlobalController.to.token != null && GlobalController.to.token != '')
        'Authorization': 'Bearer ${GlobalController.to.token}',
      'Accept': 'application/json',
      'Accept-Language': GlobalController.to.currentLocale.languageCode,
      'Accept-Encoding': 'gzip, deflate, br',
      'Connection': 'keep-alive',
      'AppVersion': "${AppConfig.appVersion}",
    });
    if (kDebugMode) {
      log('API ${options.method} ${options.uri.path}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      log('API ${response.statusCode} ${response.requestOptions.uri.path}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      log(
        'API error ${err.response?.statusCode ?? '-'} '
        '${err.requestOptions.uri.path}: ${err.type.name}',
      );
    }
    handler.next(err);
  }
}

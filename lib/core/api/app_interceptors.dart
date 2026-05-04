import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:alma_desktop/features/global/presentation/controllers/global_controller.dart';
import '../config/app_config.dart';

class AppInterceptos implements Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // if (getx.Get.isSnackbarOpen) {
    //   getx.Get.closeAllSnackbars();
    // }
    // log request data
    log('request options: ${options.headers}');
    log('request data: ${options.data}');

    if (!options.headers.containsKey('Content-Type')) {
      options.headers['Content-Type'] = 'application/json';
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
    log(options.headers.toString());
    // log((options.data as FormData).fields.toString());
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    log(response.data.toString());
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}

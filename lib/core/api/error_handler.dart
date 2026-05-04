import 'dart:developer';

import 'package:get/get.dart';

import '../errors/app_messages.dart';
import '../errors/exceptions.dart';
import '../errors/failures.dart';

class NetworkErrorHandler {
  static CustomException networkHandler(e) {
    log("This is socket exception from the network handler $e");
    var exception = "$e";
    if (exception.contains("HttpException")) {
      throw NoInternetException("${"no_internet_access".tr} $e");
    } else {
      throw RequestTimeoutException("unknown_error".tr);
    }
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

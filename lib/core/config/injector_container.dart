import 'package:alma_desktop/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:alma_desktop/features/auth/data/datasources/auth_remote_data_soruce.dart';
import 'package:alma_desktop/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:alma_desktop/features/auth/domain/repositories/auth_repository.dart';
import 'package:alma_desktop/features/auth/domain/usecases/login_use_case.dart';
import 'package:alma_desktop/features/auth/domain/usecases/forget_password_use_case.dart';
import 'package:alma_desktop/features/auth/domain/usecases/validate_otp_use_case.dart';
import 'package:alma_desktop/features/auth/domain/usecases/reset_password_use_case.dart';
import 'package:alma_desktop/features/auth/domain/usecases/get_me_use_case.dart';
import 'package:alma_desktop/features/auth/domain/usecases/change_password_use_case.dart';
import 'package:alma_desktop/features/auth/domain/usecases/update_profile_use_case.dart';
import 'package:alma_desktop/features/global/data/datasources/global_local_data_source.dart';
import 'package:alma_desktop/features/global/data/repositories/global_repository_impl.dart';
import 'package:alma_desktop/features/global/domain/repositories/global_repository.dart';
import 'package:alma_desktop/features/global/domain/usecases/check_if_user_is_logged_in_use_case.dart';
import 'package:alma_desktop/features/global/presentation/controllers/global_controller.dart';
import 'package:alma_desktop/features/main/data/datasources/main_remote_data_source.dart';
import 'package:alma_desktop/features/main/data/repositories/main_repository_impl.dart';
import 'package:alma_desktop/features/main/domain/repositories/main_repository.dart';
import 'package:alma_desktop/features/main/domain/usecases/assign_deal_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/check_in_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/check_out_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_attendance_status_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_today_total_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_week_total_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_deals_stats_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_messages_line_chart_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_messages_stats_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_weekly_stats_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/update_deal_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_agents_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/delete_notification_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_deal_by_id_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_deal_messages_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_lost_deals_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_notifications_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_notifications_unread_count_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/mark_all_notifications_as_read_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/mark_notification_as_read_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_open_deals_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_won_deals_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/send_message_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/update_message_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/delete_message_use_case.dart';
// import 'package:alma_desktop/features/main/presentation/controllers/home_controller.dart';
// import 'package:alma_desktop/features/main/presentation/controllers/notifications_controller.dart';
// import 'package:alma_desktop/features/main/presentation/controllers/onboarding_controller.dart';
import 'package:dio/dio.dart';
// import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_consumer.dart';
import '../api/dio_consumer.dart';
import '../services/local_storage_service/local_storage_service.dart';
import '../services/local_storage_service/local_storage_service_shared_preferences_impl.dart';
// import '../services/firebase_services/firebase_services.dart';

class InjectorContainer {
  static Future<void> init() async {
    // Externals
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    // Services - يجب تسجيلها قبل Firebase لأن FCMTokenService يحتاج LocalStorageService
    Get.lazyPut(() => Dio(), fenix: true);
    Get.lazyPut<ApiConsumer>(
      () => DioConsumer(client: Get.find()),
      fenix: true,
    );
    Get.lazyPut<LocalStorageService>(
      () => LocalStorageServiceSharedPreferencesImpl(preferences),
      fenix: true,
    );

    // Firebase (يعتمد على LocalStorageService)
    // try {
    //   await FirebaseServices().dependencies();
    // } catch (e) {
    //   if (kDebugMode) {
    //     print(e);
    //   }
    // }

    // Get.put(HomeController());
    GlobalInjector.init();
    MainFeatureInjector.init();
    AuthFeatureInjector.init();
  }
}

class GlobalInjector {
  static void init() {
    // Core
    // Get.put(NetworkCheckerController());

    // Data Sources
    Get.lazyPut<GlobalLocalDataSource>(
      () => GlobalLocalDataSourceImpl(localStorageService: Get.find()),
      fenix: true,
    );
    // Get.lazyPut<GlobalRemoteDataSource>(
    //   () => GlobalRemoteDataSourceImpl(apiConsumer: Get.find()),
    //   fenix: true,
    // );
    // // // Repositories
    Get.lazyPut<GlobalRepository>(
      () => GlobalRepositoryImpl(globalLocalDataSource: Get.find()),
      fenix: true,
    );
    // // UseCases

    // Get.lazyPut(() => AppStartUseCase(repository: Get.find()), fenix: true);
    // Get.lazyPut(() => GetCountriesUseCase(Get.find()), fenix: true);
    // Get.lazyPut(() => GetUserInfoUseCase(Get.find()), fenix: true);
    Get.lazyPut(
      () => CheckIfUserIsLoggedInUseCase(globalRepository: Get.find()),
      fenix: true,
    );

    // Contorllers
    // Get.put(AppStartController(Get.find()));
    Get.put(GlobalController(checkIfUserIsLoggedInUseCase: Get.find()));
  }
}

class AuthFeatureInjector {
  static void init() {
    // Data Sources
    Get.lazyPut<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(localStorageService: Get.find()),
      fenix: true,
    );
    Get.lazyPut<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(apiConsumer: Get.find()),
      fenix: true,
    );

    // // // Repositories
    Get.lazyPut<AuthRepository>(
      () => AuthRepositoryImpl(
        authLocalDataSource: Get.find(),
        authRemoteDataSource: Get.find(),
      ),
      fenix: true,
    );
    // // UseCases
    Get.lazyPut(() => LoginUseCase(authRepository: Get.find()), fenix: true);
    Get.lazyPut(
      () => ForgetPasswordUseCase(authRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut(
      () => ValidateOtpUseCase(authRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut(
      () => ResetPasswordUseCase(authRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut(() => GetMeUseCase(authRepository: Get.find()), fenix: true);
    Get.lazyPut(
      () => UpdateProfileUseCase(authRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut(
      () => ChangePasswordUseCase(authRepository: Get.find()),
      fenix: true,
    );

    // Controllers
    // Get.put(
    //   LoginController(loginUseCase: Get.find(), globalController: Get.find()),
    //   permanent: true,
    // );
    // Get.lazyPut(
    //   () => ForgetPasswordController(forgetPasswordUseCase: Get.find()),
    //   fenix: true,
    // );
    // Get.lazyPut(
    //   () => OtpController(validateOtpUseCase: Get.find()),
    //   fenix: true,
    // );
    // Get.lazyPut(
    //   () => ResetPasswordController(resetPasswordUseCase: Get.find()),
    //   fenix: true,
    // );
  }
}

class MainFeatureInjector {
  static void init() {
    // Data Sources
    Get.lazyPut<MainRemoteDataSource>(
      () => MainRemoteDataSourceImpl(apiConsumer: Get.find()),
      fenix: true,
    );

    // Repositories
    Get.lazyPut<MainRepository>(
      () => MainRepositoryImpl(mainRemoteDataSource: Get.find()),
      fenix: true,
    );

    // UseCases
    Get.lazyPut(
      () => GetDealByIdUseCase(mainRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetDealMessagesUseCase(mainRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetOpenDealsUseCase(mainRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetLostDealsUseCase(mainRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetWonDealsUseCase(mainRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut(
      () => SendMessageUseCase(mainRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut(
      () => UpdateMessageUseCase(mainRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut(
      () => DeleteMessageUseCase(mainRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetAgentsUseCase(mainRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut(
      () => AssignDealUseCase(mainRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut(
      () => UpdateDealUseCase(mainRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut(() => CheckInUseCase(mainRepository: Get.find()), fenix: true);
    Get.lazyPut(() => CheckOutUseCase(mainRepository: Get.find()), fenix: true);
    Get.lazyPut(
      () => GetAttendanceStatusUseCase(mainRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetTodayTotalUseCase(mainRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetWeekTotalUseCase(mainRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetWeeklyStatsUseCase(mainRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetDealsStatsUseCase(mainRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetMessagesStatsUseCase(mainRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetMessagesLineChartUseCase(mainRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetNotificationsUseCase(mainRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetNotificationsUnreadCountUseCase(mainRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut(
      () => MarkAllNotificationsAsReadUseCase(mainRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut(
      () => MarkNotificationAsReadUseCase(mainRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut(
      () => DeleteNotificationUseCase(mainRepository: Get.find()),
      fenix: true,
    );

    // Controllers (SplashController: يُسجَّل عبر binding في AppRoutes.splash فقط)
    // Get.lazyPut(() => OnboardingController(), fenix: true);
    // Get.lazyPut(
    //   () => HomeController(
    //     Get.find<GetAttendanceStatusUseCase>(),
    //     Get.find<GetTodayTotalUseCase>(),
    //     Get.find<GetWeekTotalUseCase>(),
    //     Get.find<GetWeeklyStatsUseCase>(),
    //     Get.find<GetDealsStatsUseCase>(),
    //     Get.find<GetMessagesStatsUseCase>(),
    //     Get.find<GetMessagesLineChartUseCase>(),
    //     Get.find<GetOpenDealsUseCase>(),
    //   ),
    //   fenix: true,
    // );
    // Get.lazyPut(
    //   () => NotificationsController(
    //     Get.find<GetNotificationsUseCase>(),
    //     Get.find<GetNotificationsUnreadCountUseCase>(),
    //     Get.find<DeleteNotificationUseCase>(),
    //     Get.find<MarkAllNotificationsAsReadUseCase>(),
    //     Get.find<MarkNotificationAsReadUseCase>(),
    //   ),
    //   fenix: true,
    // );
  }
}

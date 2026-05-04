import 'package:alma_desktop/core/middlewares/check_auth_middleware.dart';
import 'package:alma_desktop/features/auth/presentation/controllers/login_controller.dart';
import 'package:alma_desktop/features/auth/domain/usecases/update_profile_use_case.dart';
import 'package:alma_desktop/features/auth/presentation/views/login_view.dart';
import 'package:alma_desktop/features/global/presentation/controllers/global_controller.dart';
import 'package:alma_desktop/features/main/presentation/controllers/splash_controller.dart';
import 'package:alma_desktop/features/main/presentation/controllers/chat_controller.dart';
import 'package:alma_desktop/features/main/presentation/controllers/dashboard_controller.dart';
import 'package:alma_desktop/features/main/presentation/controllers/main_controller.dart';
import 'package:alma_desktop/features/main/presentation/controllers/profile_controller.dart';
import 'package:alma_desktop/features/main/presentation/controllers/crm_kanban_controller.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_deals_stats_use_case.dart';
import 'package:alma_desktop/features/main/presentation/views/main_view.dart';
import 'package:alma_desktop/features/main/presentation/views/splash_view.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_messages_line_chart_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_messages_stats_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_today_total_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_week_total_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_weekly_stats_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_deal_messages_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_agents_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/check_in_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/check_out_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_attendance_status_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_lost_deals_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_open_deals_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/assign_deal_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/send_message_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/update_deal_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_won_deals_use_case.dart';
import 'package:get/get.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String main = '/main';
  static const String login = '/login';
  static const String forgetPassword = '/forget_password';
  static const String otp = '/otp';
  static const String resetPassword = '/reset_password';
  static const String chatDetails = '/chat_details';
  static const String transferDeal = '/transfer_deal';
  static const String editProfile = '/edit_profile';
  static const String updatePassword = '/update_password';
  static const String notifications = '/notifications';
  static final List<GetPage> routes = [
    GetPage(
      name: splash,
      page: () => const SplashView(),
      binding: BindingsBuilder(() {
        Get.put(SplashController());
      }),
    ),
    // GetPage(name: onboarding, page: () => const OnboardingView()),
    GetPage(
      name: login,
      page: () => const LoginView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(
          () => LoginController(
            loginUseCase: Get.find(),
            globalController: Get.find<GlobalController>(),
          ),
        );
      }),
    ),
    // GetPage(name: forgetPassword, page: () => const ForgetPasswordView()),
    // GetPage(name: otp, page: () => const OtpView()),
    // GetPage(name: resetPassword, page: () => const ResetPasswordView()),
    GetPage(
      name: main,
      page: () => const MainView(),
      middlewares: [CheckAuthMiddleware()],
      binding: BindingsBuilder(() {
        Get.lazyPut(() => MainController());
        Get.lazyPut(
          () => DashboardController(
            getDealsStatsUseCase: Get.find<GetDealsStatsUseCase>(),
            getMessagesStatsUseCase: Get.find<GetMessagesStatsUseCase>(),
            getAttendanceStatusUseCase: Get.find<GetAttendanceStatusUseCase>(),
            checkInUseCase: Get.find<CheckInUseCase>(),
            checkOutUseCase: Get.find<CheckOutUseCase>(),
            getTodayTotalUseCase: Get.find<GetTodayTotalUseCase>(),
            getWeekTotalUseCase: Get.find<GetWeekTotalUseCase>(),
            getWeeklyStatsUseCase: Get.find<GetWeeklyStatsUseCase>(),
            getMessagesLineChartUseCase: Get.find<GetMessagesLineChartUseCase>(),
          ),
          fenix: true,
        );
        Get.lazyPut(
          () => CrmKanbanController(
            getOpenDealsUseCase: Get.find<GetOpenDealsUseCase>(),
            getWonDealsUseCase: Get.find<GetWonDealsUseCase>(),
            getLostDealsUseCase: Get.find<GetLostDealsUseCase>(),
            updateDealUseCase: Get.find<UpdateDealUseCase>(),
            getAgentsUseCase: Get.find<GetAgentsUseCase>(),
            assignDealUseCase: Get.find<AssignDealUseCase>(),
          ),
          fenix: true,
        );
        Get.lazyPut(
          () => ChatController(
            getOpenDealsUseCase: Get.find<GetOpenDealsUseCase>(),
            getWonDealsUseCase: Get.find<GetWonDealsUseCase>(),
            getLostDealsUseCase: Get.find<GetLostDealsUseCase>(),
            getDealMessagesUseCase: Get.find<GetDealMessagesUseCase>(),
            sendMessageUseCase: Get.find<SendMessageUseCase>(),
          ),
          fenix: true,
        );
        Get.lazyPut(
          () => ProfileController(
            updateProfileUseCase: Get.find<UpdateProfileUseCase>(),
          ),
          fenix: true,
        );
      }),
    ),
    // GetPage(name: chatDetails, page: () => const ChatDetailsView()),
    // GetPage(name: transferDeal, page: () => const TransferDealView()),
    // GetPage(name: editProfile, page: () => const EditProfileView()),
    // GetPage(name: updatePassword, page: () => const UpdatePasswordView()),
    // GetPage(name: notifications, page: () => const NotificationsView()),
  ];
}

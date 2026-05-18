import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:alma_desktop/core/config/app_routes.dart';
import 'package:alma_desktop/features/calls/presentation/views/calls_view.dart';
import 'package:alma_desktop/features/global/presentation/controllers/global_controller.dart';
import 'package:alma_desktop/features/main/presentation/views/chat_view.dart';
import 'package:alma_desktop/features/main/presentation/views/crm_kanban_view.dart';
import 'package:alma_desktop/features/main/presentation/views/dashboard_view.dart';
import 'package:alma_desktop/features/main/presentation/views/profile_view.dart';
import 'package:alma_desktop/features/main/presentation/views/update_view.dart';

class MainController extends GetxController {
  int selectedIndex = 0;

  late final List<Widget> views;

  @override
  void onInit() {
    super.onInit();
    views = [
      const DashboardView(),
      const CrmKanbanView(),
      const ChatView(),
      const CallsView(),
      const ProfileView(),
      const UpdateView(),
    ];
  }

  void changeView(int index) {
    if (index < 0 || index >= views.length) return;
    selectedIndex = index;
    update();
  }

  void logout() {
    GlobalController.to.clearLogedIn();
    Get.offAllNamed(AppRoutes.login);
  }
}

import 'dart:async';

import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/global/presentation/controllers/global_controller.dart';
import 'package:alma_desktop/features/main/domain/entities/attendance.dart';
import 'package:alma_desktop/features/main/domain/usecases/check_in_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/check_out_use_case.dart';
import 'package:alma_desktop/features/main/domain/entities/attendance_time_total.dart';
import 'package:alma_desktop/features/main/domain/entities/attendance_weekly_stat.dart';
import 'package:alma_desktop/features/main/domain/entities/deal_stats.dart';
import 'package:alma_desktop/features/main/domain/entities/message_line_chart_data.dart';
import 'package:alma_desktop/features/main/domain/entities/message_stats.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_attendance_status_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_deals_stats_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_messages_line_chart_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_messages_stats_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_today_total_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_week_total_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_weekly_stats_use_case.dart';
import 'package:get/get.dart';

class DashboardController extends GetxController {
  DashboardController({
    required this.getDealsStatsUseCase,
    required this.getMessagesStatsUseCase,
    required this.getAttendanceStatusUseCase,
    required this.checkInUseCase,
    required this.checkOutUseCase,
    required this.getTodayTotalUseCase,
    required this.getWeekTotalUseCase,
    required this.getWeeklyStatsUseCase,
    required this.getMessagesLineChartUseCase,
  });

  final GetDealsStatsUseCase getDealsStatsUseCase;
  final GetMessagesStatsUseCase getMessagesStatsUseCase;
  final GetAttendanceStatusUseCase getAttendanceStatusUseCase;
  final CheckInUseCase checkInUseCase;
  final CheckOutUseCase checkOutUseCase;
  final GetTodayTotalUseCase getTodayTotalUseCase;
  final GetWeekTotalUseCase getWeekTotalUseCase;
  final GetWeeklyStatsUseCase getWeeklyStatsUseCase;
  final GetMessagesLineChartUseCase getMessagesLineChartUseCase;
  Timer? _sessionTimer;

  bool isLoading = true;
  bool isRefreshing = false;
  bool isAttendanceLoading = false;
  bool isAttendanceActionLoading = false;
  String? errorMessage;
  String? attendanceErrorMessage;

  DealStats? dealsStats;
  MessageStats? messageStats;
  Attendance? attendanceStatus;
  AttendanceTimeTotal? todayTotal;
  AttendanceTimeTotal? weekTotal;
  List<AttendanceWeeklyStat> weeklyStats = const [];
  List<MessageLineChartData> messageLineChart = const [];
  int sessionElapsedSeconds = 0;

  bool get isAgent => (GlobalController.to.user?.roles ?? const [])
      .any((role) => role.toLowerCase() == 'agent');

  bool get isClockedIn => attendanceStatus?.isClockedIn == true;

  String get formattedSessionElapsed {
    final duration = Duration(seconds: sessionElapsedSeconds);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  bool get hasAnyData =>
      dealsStats != null ||
      messageStats != null ||
      todayTotal != null ||
      weekTotal != null ||
      weeklyStats.isNotEmpty ||
      messageLineChart.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
    if (isAgent) {
      loadAttendanceStatus();
    }
  }

  Future<void> loadDashboard({bool refresh = false}) async {
    if (refresh) {
      isRefreshing = true;
    } else {
      isLoading = true;
    }
    errorMessage = null;
    update();

    String? firstFailureMessage;
    final params = NoParams();
    final results = await Future.wait([
      getDealsStatsUseCase(params),
      getMessagesStatsUseCase(params),
      getTodayTotalUseCase(params),
      getWeekTotalUseCase(params),
      getWeeklyStatsUseCase(params),
      getMessagesLineChartUseCase(params),
    ]);

    results[0].fold(
      (failure) => firstFailureMessage ??= failure.message ?? 'failed_to_load_dashboard'.tr,
      (value) => dealsStats = value as DealStats,
    );
    results[1].fold(
      (failure) => firstFailureMessage ??= failure.message ?? 'failed_to_load_dashboard'.tr,
      (value) => messageStats = value as MessageStats,
    );
    results[2].fold(
      (failure) => firstFailureMessage ??= failure.message ?? 'failed_to_load_dashboard'.tr,
      (value) => todayTotal = value as AttendanceTimeTotal,
    );
    results[3].fold(
      (failure) => firstFailureMessage ??= failure.message ?? 'failed_to_load_dashboard'.tr,
      (value) => weekTotal = value as AttendanceTimeTotal,
    );
    results[4].fold(
      (failure) => firstFailureMessage ??= failure.message ?? 'failed_to_load_dashboard'.tr,
      (value) => weeklyStats = List<AttendanceWeeklyStat>.from(value as List),
    );
    results[5].fold(
      (failure) => firstFailureMessage ??= failure.message ?? 'failed_to_load_dashboard'.tr,
      (value) => messageLineChart = List<MessageLineChartData>.from(value as List),
    );

    if (!hasAnyData) {
      errorMessage = firstFailureMessage ?? 'failed_to_load_dashboard'.tr;
    }

    isLoading = false;
    isRefreshing = false;
    update();

    if (isAgent) {
      await loadAttendanceStatus(silent: true);
    }
  }

  Future<void> loadAttendanceStatus({bool silent = false}) async {
    if (!isAgent) return;
    if (!silent) {
      isAttendanceLoading = true;
      attendanceErrorMessage = null;
      update();
    }

    final result = await getAttendanceStatusUseCase(NoParams());
    result.fold(
      (failure) {
        attendanceErrorMessage =
            failure.message ?? 'failed_to_load_dashboard'.tr;
      },
      (value) {
        attendanceStatus = value;
        attendanceErrorMessage = null;
        _syncSessionTimer();
      },
    );

    if (!silent) {
      isAttendanceLoading = false;
      update();
    } else {
      update();
    }
  }

  Future<void> toggleClockStatus() async {
    if (!isAgent || isAttendanceActionLoading) return;
    isAttendanceActionLoading = true;
    attendanceErrorMessage = null;
    update();

    final result = isClockedIn
        ? await checkOutUseCase(const CheckOutParams())
        : await checkInUseCase(const CheckInParams());

    await result.fold<Future<void>>(
      (failure) async {
        attendanceErrorMessage =
            failure.message ?? 'failed_to_load_dashboard'.tr;
      },
      (value) async {
        attendanceStatus = value;
        attendanceErrorMessage = null;
        _syncSessionTimer();
        await _reloadAttendanceAggregates();
        await loadAttendanceStatus(silent: true);
      },
    );

    isAttendanceActionLoading = false;
    update();
  }

  /// بعد تسجيل الدخول/الخروج نحدّث أرقام اليوم والأسبوع والرسم لأن الحالة تغيّرت.
  Future<void> _reloadAttendanceAggregates() async {
    if (!isAgent) return;
    final params = NoParams();
    final results = await Future.wait([
      getTodayTotalUseCase(params),
      getWeekTotalUseCase(params),
      getWeeklyStatsUseCase(params),
    ]);

    results[0].fold(
      (_) {},
      (value) => todayTotal = value as AttendanceTimeTotal,
    );
    results[1].fold(
      (_) {},
      (value) => weekTotal = value as AttendanceTimeTotal,
    );
    results[2].fold(
      (_) {},
      (value) =>
          weeklyStats = List<AttendanceWeeklyStat>.from(value as List),
    );
  }

  void _syncSessionTimer() {
    _sessionTimer?.cancel();
    if (!isClockedIn || attendanceStatus?.clockInAt == null) {
      sessionElapsedSeconds = attendanceStatus?.totalSeconds ?? 0;
      return;
    }

    sessionElapsedSeconds = DateTime.now()
        .difference(attendanceStatus!.clockInAt!)
        .inSeconds
        .clamp(0, 86400 * 2)
        .toInt();

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      sessionElapsedSeconds += 1;
      update();
    });
  }

  @override
  void onClose() {
    _sessionTimer?.cancel();
    super.onClose();
  }
}

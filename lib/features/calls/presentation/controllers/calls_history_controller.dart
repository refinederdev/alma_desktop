import 'package:alma_desktop/core/errors/app_messages.dart';
import 'package:alma_desktop/features/calls/domain/entities/call_session.dart';
import 'package:alma_desktop/features/calls/domain/entities/whatsapp_call.dart';
import 'package:alma_desktop/features/calls/domain/usecases/calls_use_cases.dart';
import 'package:alma_desktop/features/calls/presentation/controllers/call_controller.dart';
import 'package:get/get.dart';

class CallsHistoryController extends GetxController {
  CallsHistoryController({required this.getCallHistoryUseCase});

  final GetCallHistoryUseCase getCallHistoryUseCase;

  bool isLoading = false;
  bool isRefreshing = false;
  bool isLoadingMore = false;
  String? errorMessage;
  int _currentPage = 1;
  bool _hasMorePages = false;

  int? selectedSessionId;
  String? filterDirection; // inbound | outbound | null
  String? filterStatus; // completed | rejected | missed | in_progress | null

  List<WhatsAppCall> calls = const [];

  List<CallSession> get availableSessions =>
      Get.find<CallController>().sessions;

  bool get hasMore => _hasMorePages;

  @override
  void onReady() {
    super.onReady();
    // ensure call controller initialized & default session
    final cc = Get.find<CallController>();
    if (!cc.isInitialized) {
      cc.initialize();
    }
    if (selectedSessionId == null && cc.sessions.isNotEmpty) {
      selectedSessionId = cc.sessions.first.id;
      load();
    } else if (selectedSessionId != null) {
      load();
    }
  }

  Future<void> changeSession(int sessionId) async {
    selectedSessionId = sessionId;
    calls = const [];
    _currentPage = 1;
    _hasMorePages = false;
    update();
    await load();
  }

  Future<void> changeDirection(String? direction) async {
    filterDirection = direction;
    await load();
  }

  Future<void> changeStatus(String? status) async {
    filterStatus = status;
    await load();
  }

  Future<void> load({bool refresh = false}) async {
    final sessionId = selectedSessionId;
    if (sessionId == null) return;
    if (refresh) {
      isRefreshing = true;
    } else {
      isLoading = true;
    }
    errorMessage = null;
    update();

    final result = await getCallHistoryUseCase(
      GetCallHistoryParams(
        sessionId: sessionId,
        page: 1,
        perPage: 20,
        direction: filterDirection,
        status: filterStatus,
      ),
    );
    result.fold(
      (failure) {
        errorMessage = failure.message;
        AppMessages.showSnackBar(
          type: ErrorType.error,
          title: 'error'.tr,
          message: failure.message,
        );
      },
      (paginator) {
        calls = paginator.data;
        _currentPage = paginator.currentPage;
        _hasMorePages = paginator.hasMorePages;
      },
    );

    isLoading = false;
    isRefreshing = false;
    update();
  }

  Future<void> loadMore() async {
    if (!_hasMorePages || isLoadingMore || isLoading) return;
    final sessionId = selectedSessionId;
    if (sessionId == null) return;
    isLoadingMore = true;
    update();

    final nextPage = _currentPage + 1;
    final result = await getCallHistoryUseCase(
      GetCallHistoryParams(
        sessionId: sessionId,
        page: nextPage,
        perPage: 20,
        direction: filterDirection,
        status: filterStatus,
      ),
    );
    result.fold(
      (failure) {
        AppMessages.showSnackBar(
          type: ErrorType.error,
          title: 'error'.tr,
          message: failure.message,
        );
      },
      (paginator) {
        calls = [...calls, ...paginator.data];
        _currentPage = paginator.currentPage;
        _hasMorePages = paginator.hasMorePages;
      },
    );

    isLoadingMore = false;
    update();
  }
}

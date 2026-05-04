import 'package:alma_desktop/core/errors/app_messages.dart';
import 'package:alma_desktop/core/config/app_config.dart';
import 'package:alma_desktop/core/services/reverb_service/reverb_service.dart';
import 'package:alma_desktop/features/auth/domain/entities/user.dart';
import 'package:alma_desktop/features/global/presentation/controllers/global_controller.dart';
import 'package:alma_desktop/features/main/data/models/deal_last_message_model.dart';
import 'package:alma_desktop/features/main/data/models/deal_model.dart';
import 'package:alma_desktop/features/main/domain/entities/agent.dart';
import 'package:alma_desktop/features/main/domain/entities/deal.dart';
import 'package:alma_desktop/features/main/domain/usecases/assign_deal_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_deals_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_agents_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_lost_deals_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_open_deals_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/update_deal_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_won_deals_use_case.dart';
import 'package:alma_desktop/features/main/presentation/controllers/chat_controller.dart';
import 'package:alma_desktop/features/main/presentation/controllers/main_controller.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum CrmDealStatus { open, won, lost }

extension CrmDealStatusX on CrmDealStatus {
  String get apiValue {
    switch (this) {
      case CrmDealStatus.open:
        return 'open';
      case CrmDealStatus.won:
        return 'won';
      case CrmDealStatus.lost:
        return 'lost';
    }
  }
}

class CrmKanbanController extends GetxController {
  final GetOpenDealsUseCase getOpenDealsUseCase;
  final GetWonDealsUseCase getWonDealsUseCase;
  final GetLostDealsUseCase getLostDealsUseCase;
  final UpdateDealUseCase updateDealUseCase;
  final GetAgentsUseCase getAgentsUseCase;
  final AssignDealUseCase assignDealUseCase;

  CrmKanbanController({
    required this.getOpenDealsUseCase,
    required this.getWonDealsUseCase,
    required this.getLostDealsUseCase,
    required this.updateDealUseCase,
    required this.getAgentsUseCase,
    required this.assignDealUseCase,
  });

  bool isLoading = true;
  bool isRefreshing = false;
  static const int _dealsPerPage = 30;

  List<Deal> openDeals = const [];
  List<Deal> wonDeals = const [];
  List<Deal> lostDeals = const [];
  final Set<int> _updatingDealIds = <int>{};
  final Set<int> _actionRunningDealIds = <int>{};
  final Map<CrmDealStatus, int> _currentPageByStatus = <CrmDealStatus, int>{
    CrmDealStatus.open: 1,
    CrmDealStatus.won: 1,
    CrmDealStatus.lost: 1,
  };
  final Map<CrmDealStatus, bool> _hasMoreByStatus = <CrmDealStatus, bool>{
    CrmDealStatus.open: false,
    CrmDealStatus.won: false,
    CrmDealStatus.lost: false,
  };
  final Map<CrmDealStatus, bool> _isLoadingMoreByStatus = <CrmDealStatus, bool>{
    CrmDealStatus.open: false,
    CrmDealStatus.won: false,
    CrmDealStatus.lost: false,
  };

  String? errorMessage;
  ReverbService? _reverbService;
  AudioPlayer? _notificationPlayer;
  bool _isReverbConnected = false;
  final Set<String> _subscribedChannelNames = <String>{};
  final Set<String> _playedNotificationKeys = <String>{};

  int get totalDeals => openDeals.length + wonDeals.length + lostDeals.length;
  bool isDealUpdating(int dealId) =>
      _updatingDealIds.contains(dealId) || _actionRunningDealIds.contains(dealId);
  bool hasMoreDeals(CrmDealStatus status) => _hasMoreByStatus[status] ?? false;
  bool isLoadingMoreDeals(CrmDealStatus status) =>
      _isLoadingMoreByStatus[status] ?? false;
  bool get isReverbConnected => _isReverbConnected;

  @override
  void onInit() {
    super.onInit();
    _notificationPlayer = AudioPlayer();
    loadBoard().then((_) => initializeReverb());
  }

  Future<void> loadBoard({bool refresh = false}) async {
    if (refresh) {
      isRefreshing = true;
    } else {
      isLoading = true;
    }
    errorMessage = null;
    update();

    final params = const GetDealsParams(page: 1, perPage: _dealsPerPage);
    final results = await Future.wait([
      getOpenDealsUseCase(params),
      getWonDealsUseCase(params),
      getLostDealsUseCase(params),
    ]);

    String? firstFailure;

    results[0].fold(
      (failure) => firstFailure ??= failure.message ?? 'failed_to_load_open_deals'.tr,
      (paginator) {
        openDeals = paginator.data;
        _currentPageByStatus[CrmDealStatus.open] = paginator.currentPage;
        _hasMoreByStatus[CrmDealStatus.open] = paginator.hasMorePages;
      },
    );
    results[1].fold(
      (failure) => firstFailure ??= failure.message ?? 'failed_to_load_won_deals'.tr,
      (paginator) {
        wonDeals = paginator.data;
        _currentPageByStatus[CrmDealStatus.won] = paginator.currentPage;
        _hasMoreByStatus[CrmDealStatus.won] = paginator.hasMorePages;
      },
    );
    results[2].fold(
      (failure) => firstFailure ??= failure.message ?? 'failed_to_load_lost_deals'.tr,
      (paginator) {
        lostDeals = paginator.data;
        _currentPageByStatus[CrmDealStatus.lost] = paginator.currentPage;
        _hasMoreByStatus[CrmDealStatus.lost] = paginator.hasMorePages;
      },
    );

    isLoading = false;
    isRefreshing = false;
    errorMessage = firstFailure;
    update();

    if (firstFailure != null) {
      AppMessages.showSnackBar(
        type: ErrorType.error,
        title: 'error'.tr,
        message: firstFailure,
      );
    }
  }

  Future<void> loadMoreDealsByStatus(CrmDealStatus status) async {
    final hasMore = _hasMoreByStatus[status] ?? false;
    final isLoadingMore = _isLoadingMoreByStatus[status] ?? false;
    if (!hasMore || isLoadingMore || isLoading || isRefreshing) return;

    _isLoadingMoreByStatus[status] = true;
    update();

    final nextPage = (_currentPageByStatus[status] ?? 1) + 1;
    final params = GetDealsParams(page: nextPage, perPage: _dealsPerPage);

    final result = switch (status) {
      CrmDealStatus.open => getOpenDealsUseCase(params),
      CrmDealStatus.won => getWonDealsUseCase(params),
      CrmDealStatus.lost => getLostDealsUseCase(params),
    };
    final response = await result;

    response.fold(
      (failure) {
        _isLoadingMoreByStatus[status] = false;
        update();
        final fallbackMessage = switch (status) {
          CrmDealStatus.open => 'failed_to_load_open_deals'.tr,
          CrmDealStatus.won => 'failed_to_load_won_deals'.tr,
          CrmDealStatus.lost => 'failed_to_load_lost_deals'.tr,
        };
        AppMessages.showSnackBar(
          type: ErrorType.error,
          title: 'error'.tr,
          message: failure.message ?? fallbackMessage,
        );
      },
      (paginator) {
        switch (status) {
          case CrmDealStatus.open:
            openDeals = _mergeUniqueDeals(openDeals, paginator.data);
            break;
          case CrmDealStatus.won:
            wonDeals = _mergeUniqueDeals(wonDeals, paginator.data);
            break;
          case CrmDealStatus.lost:
            lostDeals = _mergeUniqueDeals(lostDeals, paginator.data);
            break;
        }
        _currentPageByStatus[status] = paginator.currentPage;
        _hasMoreByStatus[status] = paginator.hasMorePages;
        _isLoadingMoreByStatus[status] = false;
        update();
      },
    );
  }

  Future<void> refreshBoard() async {
    await loadBoard(refresh: true);
  }

  Future<void> openChatForDeal(Deal deal) async {
    final mainController = Get.find<MainController>();
    final chatController = Get.find<ChatController>();
    mainController.changeView(2);
    await chatController.selectDeal(deal, silentLoading: true);
  }

  Future<void> showEditDealDialog(Deal deal) async {
    if (_actionRunningDealIds.contains(deal.id)) return;
    final titleController = TextEditingController(text: deal.title ?? '');
    final contactNameController = TextEditingController(text: deal.contactName ?? '');
    final notesController = TextEditingController(text: deal.notes ?? '');
    var selectedStatus = deal.status;
    var isSubmitting = false;

    await Get.dialog<void>(
      StatefulBuilder(
        builder: (context, setState) {
          Future<void> save() async {
            if (isSubmitting) return;
            setState(() => isSubmitting = true);
            _actionRunningDealIds.add(deal.id);
            update();

            final result = await updateDealUseCase(
              UpdateDealParams(
                dealId: deal.id,
                title: titleController.text.trim(),
                contactName: contactNameController.text.trim(),
                notes: notesController.text.trim(),
                status: selectedStatus,
              ),
            );

            result.fold(
              (failure) {
                AppMessages.showSnackBar(
                  type: ErrorType.error,
                  title: 'error'.tr,
                  message: failure.message ?? 'failed_to_move_deal'.tr,
                );
              },
              (_) {
                Get.back<void>();
                AppMessages.showSnackBar(
                  type: ErrorType.success,
                  title: 'success'.tr,
                  message: 'deal_updated_successfully'.tr,
                );
                loadBoard(refresh: true);
              },
            );

            _actionRunningDealIds.remove(deal.id);
            update();
            if (Get.isDialogOpen == true) {
              setState(() => isSubmitting = false);
            }
          }

          return AlertDialog(
            title: Text('edit_deal'.tr),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'title'.tr,
                        hintText: 'enter_deal_title'.tr,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contactNameController,
                      decoration: InputDecoration(
                        labelText: 'contact_name'.tr,
                        hintText: 'enter_contact_name'.tr,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(labelText: 'deal_status'.tr),
                      items: [
                        DropdownMenuItem(value: 'open', child: Text('open'.tr)),
                        DropdownMenuItem(value: 'won', child: Text('won'.tr)),
                        DropdownMenuItem(value: 'lost', child: Text('lost'.tr)),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => selectedStatus = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'notes'.tr,
                        hintText: 'enter_notes'.tr,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Get.back<void>(),
                child: Text('cancel'.tr),
              ),
              FilledButton.icon(
                onPressed: isSubmitting ? null : save,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text('save'.tr),
              ),
            ],
          );
        },
      ),
      barrierDismissible: !isSubmitting,
    );
  }

  Future<void> showTransferDealDialog(Deal deal) async {
    if (!deal.isOpen) {
      AppMessages.showSnackBar(
        type: ErrorType.warning,
        title: 'info'.tr,
        message: 'deal_closed_cannot_transfer'.tr,
      );
      return;
    }
    if (_actionRunningDealIds.contains(deal.id)) return;

    _actionRunningDealIds.add(deal.id);
    update();
    final agentsResult = await getAgentsUseCase(const GetAgentsParams());
    _actionRunningDealIds.remove(deal.id);
    update();

    final agents = agentsResult.fold<List<Agent>>((failure) {
      AppMessages.showSnackBar(
        type: ErrorType.error,
        title: 'error'.tr,
        message: failure.message ?? 'failed_to_load_open_deals'.tr,
      );
      return const [];
    }, (data) => data);
    if (agents.isEmpty) return;

    final candidates = agents
        .where((agent) => agent.id != deal.userId)
        .toList(growable: false);
    if (candidates.isEmpty) {
      AppMessages.showSnackBar(
        type: ErrorType.info,
        title: 'info'.tr,
        message: 'no_agents_available_for_transfer'.tr,
      );
      return;
    }

    int? selectedAgentId;
    for (final agent in candidates) {
      if (agent.isActive) {
        selectedAgentId = agent.id;
        break;
      }
    }
    var searchQuery = '';
    var isSubmitting = false;
    await Get.dialog<void>(
      StatefulBuilder(
        builder: (context, setState) {
          final normalizedQuery = searchQuery.trim().toLowerCase();
          final filteredCandidates = normalizedQuery.isEmpty
              ? candidates
              : candidates.where((agent) {
                  final fullName = agent.fullName.toLowerCase();
                  final email = agent.email.toLowerCase();
                  final phone = agent.phone.toLowerCase();
                  return fullName.contains(normalizedQuery) ||
                      email.contains(normalizedQuery) ||
                      phone.contains(normalizedQuery);
                }).toList(growable: false);

          Future<void> transfer() async {
            final agentId = selectedAgentId;
            if (agentId == null || isSubmitting) return;
            setState(() => isSubmitting = true);
            _actionRunningDealIds.add(deal.id);
            update();

            final result = await assignDealUseCase(
              AssignDealParams(dealId: deal.id, userId: agentId),
            );
            result.fold(
              (failure) {
                AppMessages.showSnackBar(
                  type: ErrorType.error,
                  title: 'error'.tr,
                  message: failure.message ?? 'failed_to_transfer_deal'.tr,
                );
              },
              (_) {
                Get.back<void>();
                AppMessages.showSnackBar(
                  type: ErrorType.success,
                  title: 'success'.tr,
                  message: 'deal_transferred_successfully'.tr,
                );
                loadBoard(refresh: true);
              },
            );

            _actionRunningDealIds.remove(deal.id);
            update();
            if (Get.isDialogOpen == true) {
              setState(() => isSubmitting = false);
            }
          }

          return AlertDialog(
            title: Text('transfer_deal'.tr),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    enabled: !isSubmitting,
                    onChanged: (value) => setState(() => searchQuery = value),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: 'search_in_agents'.tr,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 360),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEBECEE)),
                    ),
                    child: filteredCandidates.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 22),
                              child: Text(
                                'no_agents_found'.tr,
                                style: const TextStyle(color: Color(0xFF777F8C)),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: filteredCandidates.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final agent = filteredCandidates[index];
                              final initials =
                                  '${agent.firstName.isNotEmpty ? agent.firstName[0] : ''}'
                                      '${agent.lastName.isNotEmpty ? agent.lastName[0] : ''}'
                                      .toUpperCase();
                              final isActive = agent.isActive;
                              return RadioListTile<int>(
                                value: agent.id,
                                groupValue: selectedAgentId,
                                onChanged: isSubmitting || !isActive
                                    ? null
                                    : (value) => setState(() => selectedAgentId = value),
                                title: Row(
                                  children: [
                                    Expanded(child: Text(agent.fullName)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? const Color(0xFFE8F7F1)
                                            : const Color(0xFFFFEEEE),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        isActive ? 'active'.tr : 'inactive'.tr,
                                        style: TextStyle(
                                          color: isActive
                                              ? const Color(0xFF17A364)
                                              : const Color(0xFFE34D4D),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text('${agent.email}\n${agent.phone}'),
                                isThreeLine: true,
                                secondary: CircleAvatar(
                                  backgroundColor: isActive
                                      ? const Color(0xFFD6F1FF)
                                      : const Color(0xFFEBECEE),
                                  child: Text(initials),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Get.back<void>(),
                child: Text('cancel'.tr),
              ),
              FilledButton.icon(
                onPressed: isSubmitting ? null : transfer,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.swap_horiz_rounded),
                label: Text('transfer'.tr),
              ),
            ],
          );
        },
      ),
      barrierDismissible: !isSubmitting,
    );
  }

  List<Deal> getDealsByStatus(CrmDealStatus status) {
    switch (status) {
      case CrmDealStatus.open:
        return openDeals;
      case CrmDealStatus.won:
        return wonDeals;
      case CrmDealStatus.lost:
        return lostDeals;
    }
  }

  Future<void> moveDealToStatus(Deal deal, CrmDealStatus targetStatus) async {
    final sourceStatus = _statusOfDeal(deal.id);
    if (sourceStatus == null || sourceStatus == targetStatus) return;

    if (_updatingDealIds.contains(deal.id)) return;
    _updatingDealIds.add(deal.id);

    final movedDeal = _removeDealFrom(sourceStatus, deal.id);
    if (movedDeal == null) {
      _updatingDealIds.remove(deal.id);
      return;
    }
    _insertDealTo(targetStatus, movedDeal);
    update();

    final result = await updateDealUseCase(
      UpdateDealParams(dealId: deal.id, status: targetStatus.apiValue),
    );

    result.fold(
      (failure) {
        _removeDealFrom(targetStatus, deal.id);
        _insertDealTo(sourceStatus, movedDeal);
        _updatingDealIds.remove(deal.id);
        update();
        AppMessages.showSnackBar(
          type: ErrorType.error,
          title: 'error'.tr,
          message: failure.message ?? 'failed_to_move_deal'.tr,
        );
      },
      (updatedDeal) {
        _removeDealFrom(targetStatus, updatedDeal.id);
        _insertDealTo(targetStatus, updatedDeal);
        _updatingDealIds.remove(updatedDeal.id);
        update();
      },
    );
  }

  CrmDealStatus? _statusOfDeal(int dealId) {
    if (openDeals.any((deal) => deal.id == dealId)) return CrmDealStatus.open;
    if (wonDeals.any((deal) => deal.id == dealId)) return CrmDealStatus.won;
    if (lostDeals.any((deal) => deal.id == dealId)) return CrmDealStatus.lost;
    return null;
  }

  Deal? _removeDealFrom(CrmDealStatus status, int dealId) {
    switch (status) {
      case CrmDealStatus.open:
        return _removeById(openDeals, dealId);
      case CrmDealStatus.won:
        return _removeById(wonDeals, dealId);
      case CrmDealStatus.lost:
        return _removeById(lostDeals, dealId);
    }
  }

  void _insertDealTo(CrmDealStatus status, Deal deal) {
    switch (status) {
      case CrmDealStatus.open:
        openDeals = [deal, ...openDeals];
        break;
      case CrmDealStatus.won:
        wonDeals = [deal, ...wonDeals];
        break;
      case CrmDealStatus.lost:
        lostDeals = [deal, ...lostDeals];
        break;
    }
  }

  Deal? _removeById(List<Deal> deals, int dealId) {
    final index = deals.indexWhere((deal) => deal.id == dealId);
    if (index == -1) return null;
    final next = List<Deal>.from(deals);
    final removed = next.removeAt(index);
    if (identical(deals, openDeals)) {
      openDeals = next;
    } else if (identical(deals, wonDeals)) {
      wonDeals = next;
    } else {
      lostDeals = next;
    }
    return removed;
  }

  List<Deal> _mergeUniqueDeals(List<Deal> current, List<Deal> incoming) {
    final map = <int, Deal>{for (final deal in current) deal.id: deal};
    for (final deal in incoming) {
      map[deal.id] = deal;
    }
    return map.values.toList();
  }

  Future<void> initializeReverb() async {
    final user = GlobalController.to.user;
    final userId = user?.id;
    if (userId == null) return;

    final token = GlobalController.to.token;
    if (token == null || token.isEmpty) return;

    try {
      _reverbService = ReverbService(
        appKey: AppConfig.reverbAppKey,
        host: AppConfig.reverbHost,
        port: AppConfig.reverbPort,
        scheme: AppConfig.reverbScheme,
        apiBaseUrl: AppConfig.baseURL,
        authToken: token,
      );

      _reverbService!.onConnected = () {
        _isReverbConnected = true;
        _safeUpdate();
      };
      _reverbService!.onConnectionError = (_) {
        _isReverbConnected = false;
        _safeUpdate();
      };
      _reverbService!.onConnectionClosed = () {
        _isReverbConnected = false;
        _safeUpdate();
      };
      _reverbService!.onMessageReceived = _handleGlobalMessage;
      _reverbService!.onDealHistoryUpdated = _handleDealHistoryUpdated;

      await _reverbService!.connect();
      await Future.delayed(const Duration(seconds: 1));

      if (_reverbService!.isConnected && _reverbService!.socketId != null) {
        await _reverbService!.subscribeToCrmAgent(userId);
        _subscribedChannelNames.add('private-crm.agent.$userId');

        if (user != null && _isAdmin(user)) {
          await _reverbService!.subscribeToCrmVisualization();
          _subscribedChannelNames.add('private-crm.visualization');
        }
      }
    } catch (e) {
      _isReverbConnected = false;
      if (kDebugMode) {
        print('❌ Error initializing CRM Reverb: $e');
      }
      _safeUpdate();
    }
  }

  void _handleGlobalMessage(Map<String, dynamic> data) {
    try {
      final messageData = data['message'] as Map<String, dynamic>?;
      final dealData = data['deal'] as Map<String, dynamic>?;
      if (messageData == null || dealData == null) return;

      final fromMe = messageData['from_me'] as bool? ?? false;
      final wasNewDeal = _upsertRealtimeDeal(
        dealData: dealData,
        messageData: messageData,
      );

      if (!fromMe) {
        _playNotificationSound(
          kind: wasNewDeal ? 'new_deal' : 'new_message',
          messageData: messageData,
          dealData: dealData,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling CRM message.received: $e');
      }
    }
  }

  void _handleDealHistoryUpdated(Map<String, dynamic> data) {
    try {
      final dealData = data['deal'] as Map<String, dynamic>?;
      if (dealData == null) return;

      final messageData = data['message'] as Map<String, dynamic>?;
      final wasNewDeal = _upsertRealtimeDeal(
        dealData: dealData,
        messageData: messageData,
      );

      if (wasNewDeal) {
        _playNotificationSound(
          kind: 'new_deal',
          messageData: messageData,
          dealData: dealData,
        );
      } else if (messageData != null && (messageData['from_me'] as bool? ?? false) == false) {
        _playNotificationSound(
          kind: 'new_message',
          messageData: messageData,
          dealData: dealData,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling CRM deal.history.updated: $e');
      }
    }
  }

  bool _upsertRealtimeDeal({
    required Map<String, dynamic> dealData,
    Map<String, dynamic>? messageData,
  }) {
    final dealId = (dealData['id'] as num?)?.toInt();
    if (dealId == null) return false;

    final existing = _findDealLocation(dealId);
    Deal? baseDeal = existing?.deal;

    if (baseDeal == null) {
      if (!DealModel.canParseFromJson(dealData)) return false;
      try {
        baseDeal = DealModel.fromJson(dealData);
      } catch (_) {
        return false;
      }
    }

    final incomingStatus = (dealData['status'] as String?) ?? baseDeal.status;
    final targetStatus = _statusFromValue(incomingStatus);
    if (targetStatus == null) return false;

    final updatedDeal = messageData != null
        ? DealModel.fromDealWithLastMessage(
            baseDeal,
            DealLastMessageModel.fromReverbPayload(
              messageData,
              baseDeal.id,
              baseDeal.crmSessionId,
            ),
          )
        : DealModel.fromDealWithLastMessage(baseDeal, baseDeal.lastMessage);

    if (existing != null) {
      final sourceList = List<Deal>.from(_dealsByStatus(existing.status))
        ..removeAt(existing.index);
      _setDealsByStatus(existing.status, sourceList);
    }

    final targetList = List<Deal>.from(_dealsByStatus(targetStatus))
      ..removeWhere((deal) => deal.id == updatedDeal.id);
    targetList.insert(0, updatedDeal);
    _setDealsByStatus(targetStatus, targetList);
    _safeUpdate();
    return existing == null;
  }

  ({CrmDealStatus status, int index, Deal deal})? _findDealLocation(int dealId) {
    final statuses = [CrmDealStatus.open, CrmDealStatus.won, CrmDealStatus.lost];
    for (final status in statuses) {
      final list = _dealsByStatus(status);
      final idx = list.indexWhere((deal) => deal.id == dealId);
      if (idx >= 0) {
        return (status: status, index: idx, deal: list[idx]);
      }
    }
    return null;
  }

  List<Deal> _dealsByStatus(CrmDealStatus status) {
    switch (status) {
      case CrmDealStatus.open:
        return openDeals;
      case CrmDealStatus.won:
        return wonDeals;
      case CrmDealStatus.lost:
        return lostDeals;
    }
  }

  void _setDealsByStatus(CrmDealStatus status, List<Deal> deals) {
    switch (status) {
      case CrmDealStatus.open:
        openDeals = deals;
        break;
      case CrmDealStatus.won:
        wonDeals = deals;
        break;
      case CrmDealStatus.lost:
        lostDeals = deals;
        break;
    }
  }

  CrmDealStatus? _statusFromValue(String? status) {
    switch (status) {
      case 'open':
        return CrmDealStatus.open;
      case 'won':
        return CrmDealStatus.won;
      case 'lost':
        return CrmDealStatus.lost;
      default:
        return null;
    }
  }

  Future<void> _playNotificationSound({
    required String kind,
    Map<String, dynamic>? messageData,
    Map<String, dynamic>? dealData,
  }) async {
    final messageId = messageData?['id'] as String? ?? messageData?['message_id'] as String?;
    final dealId = (dealData?['id'] as num?)?.toInt();
    final ts = (messageData?['timestamp'] as num?)?.toInt();
    final key = '${kind}_${dealId ?? 0}_${messageId ?? ts ?? DateTime.now().millisecondsSinceEpoch}';
    if (_playedNotificationKeys.contains(key)) return;
    _playedNotificationKeys.add(key);
    if (_playedNotificationKeys.length > 250) {
      _playedNotificationKeys.remove(_playedNotificationKeys.first);
    }

    try {
      await _notificationPlayer?.play(AssetSource('sound/notifi.wav'));
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ CRM notification sound failed: $e');
      }
    }
  }

  static bool _isAdmin(User user) {
    return user.roles.any((role) => role.toLowerCase().contains('admin'));
  }

  void _safeUpdate() {
    if (!isClosed) update();
  }

  @override
  void onClose() {
    if (_reverbService != null) {
      _reverbService!.onConnected = null;
      _reverbService!.onConnectionError = null;
      _reverbService!.onConnectionClosed = null;
      _reverbService!.onMessageReceived = null;
      _reverbService!.onDealHistoryUpdated = null;
      for (final name in _subscribedChannelNames) {
        _reverbService!.unsubscribeFromChannel(name);
      }
      _subscribedChannelNames.clear();
      _reverbService!.disconnect();
      _reverbService = null;
    }
    _notificationPlayer?.dispose();
    super.onClose();
  }
}

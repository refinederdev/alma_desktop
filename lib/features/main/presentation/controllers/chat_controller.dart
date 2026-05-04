import 'dart:async';
import 'dart:io';

import 'package:alma_desktop/core/config/app_config.dart';
import 'package:alma_desktop/core/services/file_picker_service/file_picker_service.dart';
import 'package:alma_desktop/core/errors/app_messages.dart';
import 'package:alma_desktop/core/services/reverb_service/reverb_service.dart';
import 'package:alma_desktop/features/auth/domain/entities/user.dart';
import 'package:alma_desktop/features/global/presentation/controllers/global_controller.dart';
import 'package:alma_desktop/features/main/data/models/deal_last_message_model.dart';
import 'package:alma_desktop/features/main/data/models/deal_model.dart';
import 'package:alma_desktop/features/main/domain/entities/deal.dart';
import 'package:alma_desktop/features/main/domain/entities/crm_session.dart';
import 'package:alma_desktop/features/main/domain/entities/deal_message.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_deal_messages_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_deals_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_lost_deals_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_open_deals_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_won_deals_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/send_message_use_case.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  ChatController({
    required this.getOpenDealsUseCase,
    required this.getWonDealsUseCase,
    required this.getLostDealsUseCase,
    required this.getDealMessagesUseCase,
    required this.sendMessageUseCase,
  });

  final GetOpenDealsUseCase getOpenDealsUseCase;
  final GetWonDealsUseCase getWonDealsUseCase;
  final GetLostDealsUseCase getLostDealsUseCase;
  final GetDealMessagesUseCase getDealMessagesUseCase;
  final SendMessageUseCase sendMessageUseCase;
  final FilePickerService _filePickerService = FilePickerService();

  final TextEditingController messageController = TextEditingController();
  final ScrollController messagesScrollController = ScrollController();

  static const int _messagesPerPage = 40;
  static const int _dealsPerPage = 30;
  static const Duration _dealsCacheTtl = Duration(seconds: 20);

  bool isLoadingDeals = true;
  bool isLoadingMessages = false;
  bool isLoadingOlderMessages = false;
  bool isSendingMessage = false;
  bool isRefreshing = false;
  bool isLoadingMoreDeals = false;
  bool hasOlderMessages = false;
  bool showEmojiPicker = false;

  List<Deal> allDeals = const [];
  List<Deal> filteredDeals = const [];
  List<DealMessage> messages = const [];

  String searchQuery = '';
  Deal? selectedDeal;
  File? selectedAttachment;
  String? selectedAttachmentType;
  String? dealsErrorMessage;
  String? messagesErrorMessage;
  DateTime? _lastDealsLoadedAt;
  final Map<String, int> _dealPagesByStatus = <String, int>{
    'open': 1,
    'won': 1,
    'lost': 1,
  };
  final Map<String, bool> _hasMoreDealsByStatus = <String, bool>{
    'open': false,
    'won': false,
    'lost': false,
  };
  int _messagesRequestId = 0;
  int _currentMessagesPage = 1;
  ReverbService? _reverbService;
  AudioPlayer? _notificationPlayer;
  bool _isReverbConnected = false;
  final List<String> _subscribedChannelNames = <String>[];
  final Set<String> _playedNotificationMessageIds = <String>{};

  final Map<int, List<DealMessage>> _messagesCache = <int, List<DealMessage>>{};
  final Map<int, int> _messagesPageCache = <int, int>{};
  final Map<int, bool> _hasOlderCache = <int, bool>{};
  bool get isReverbConnected => _isReverbConnected;

  @override
  void onInit() {
    super.onInit();
    _notificationPlayer = AudioPlayer();
    messagesScrollController.addListener(_onMessagesScroll);
    loadDeals().then((_) => initializeReverb());
  }

  @override
  void onClose() {
    if (_reverbService != null) {
      for (final name in _subscribedChannelNames) {
        _reverbService!.unsubscribeFromChannel(name);
      }
      _subscribedChannelNames.clear();
    }
    _reverbService?.disconnect();
    _notificationPlayer?.dispose();
    messagesScrollController.removeListener(_onMessagesScroll);
    messageController.dispose();
    messagesScrollController.dispose();
    super.onClose();
  }

  Future<void> loadDeals({bool refresh = false}) async {
    if (!refresh &&
        _lastDealsLoadedAt != null &&
        DateTime.now().difference(_lastDealsLoadedAt!) < _dealsCacheTtl &&
        allDeals.isNotEmpty) {
      return;
    }

    if (refresh) {
      isRefreshing = true;
    } else {
      isLoadingDeals = true;
    }
    dealsErrorMessage = null;
    update();

    final params = const GetDealsParams(page: 1, perPage: _dealsPerPage);
    final results = await Future.wait([
      getOpenDealsUseCase(params),
      getWonDealsUseCase(params),
      getLostDealsUseCase(params),
    ]);

    final loadedDeals = <Deal>[];
    String? firstFailure;

    results[0].fold(
      (failure) =>
          firstFailure ??= failure.message ?? 'failed_to_load_open_deals'.tr,
      (paginator) {
        loadedDeals.addAll(paginator.data);
        _dealPagesByStatus['open'] = paginator.currentPage;
        _hasMoreDealsByStatus['open'] = paginator.hasMorePages;
      },
    );
    results[1].fold(
      (failure) =>
          firstFailure ??= failure.message ?? 'failed_to_load_won_deals'.tr,
      (paginator) {
        loadedDeals.addAll(paginator.data);
        _dealPagesByStatus['won'] = paginator.currentPage;
        _hasMoreDealsByStatus['won'] = paginator.hasMorePages;
      },
    );
    results[2].fold(
      (failure) =>
          firstFailure ??= failure.message ?? 'failed_to_load_lost_deals'.tr,
      (paginator) {
        loadedDeals.addAll(paginator.data);
        _dealPagesByStatus['lost'] = paginator.currentPage;
        _hasMoreDealsByStatus['lost'] = paginator.hasMorePages;
      },
    );
    results[0].fold(
      (_) {
        _dealPagesByStatus['open'] = 1;
        _hasMoreDealsByStatus['open'] = false;
      },
      (_) {},
    );
    results[1].fold(
      (_) {
        _dealPagesByStatus['won'] = 1;
        _hasMoreDealsByStatus['won'] = false;
      },
      (_) {},
    );
    results[2].fold(
      (_) {
        _dealPagesByStatus['lost'] = 1;
        _hasMoreDealsByStatus['lost'] = false;
      },
      (_) {},
    );

    final deduplicated = _deduplicateDeals(loadedDeals);
    deduplicated.sort((a, b) {
      final aTs = a.lastMessage?.messageTimestamp ?? 0;
      final bTs = b.lastMessage?.messageTimestamp ?? 0;
      return bTs.compareTo(aTs);
    });

    allDeals = deduplicated;
    _lastDealsLoadedAt = DateTime.now();
    _applySearch();

    if (selectedDeal == null && filteredDeals.isNotEmpty) {
      await selectDeal(filteredDeals.first, silentLoading: true);
    } else if (selectedDeal != null) {
      final stillExists = allDeals.any((deal) => deal.id == selectedDeal!.id);
      if (!stillExists) {
        selectedDeal = null;
        messages = const [];
      }
    }

    dealsErrorMessage = firstFailure;
    isLoadingDeals = false;
    isRefreshing = false;
    update();

    if (firstFailure != null) {
      AppMessages.showSnackBar(
        type: ErrorType.error,
        title: 'error'.tr,
        message: firstFailure,
      );
    }
  }

  Future<void> refreshAll() async {
    await loadDeals(refresh: true);
    if (selectedDeal != null) {
      await loadMessagesForSelectedDeal(refresh: true, showLoader: false);
    }
  }

  bool get hasMoreDeals =>
      _hasMoreDealsByStatus.values.any((hasMore) => hasMore);

  Future<void> loadMoreDeals() async {
    if (isLoadingDeals || isRefreshing || isLoadingMoreDeals || !hasMoreDeals) {
      return;
    }

    isLoadingMoreDeals = true;
    update();

    final loadedDeals = <Deal>[];
    String? firstFailure;

    await Future.wait([
      _loadMoreForStatus(
        status: 'open',
        request: getOpenDealsUseCase.call,
        loadedDeals: loadedDeals,
        onFailure: (message) => firstFailure ??= message,
        fallbackErrorKey: 'failed_to_load_open_deals',
      ),
      _loadMoreForStatus(
        status: 'won',
        request: getWonDealsUseCase.call,
        loadedDeals: loadedDeals,
        onFailure: (message) => firstFailure ??= message,
        fallbackErrorKey: 'failed_to_load_won_deals',
      ),
      _loadMoreForStatus(
        status: 'lost',
        request: getLostDealsUseCase.call,
        loadedDeals: loadedDeals,
        onFailure: (message) => firstFailure ??= message,
        fallbackErrorKey: 'failed_to_load_lost_deals',
      ),
    ]);

    if (loadedDeals.isNotEmpty) {
      final merged = _deduplicateDeals([...allDeals, ...loadedDeals]);
      merged.sort((a, b) {
        final aTs = a.lastMessage?.messageTimestamp ?? 0;
        final bTs = b.lastMessage?.messageTimestamp ?? 0;
        return bTs.compareTo(aTs);
      });
      allDeals = merged;
      _applySearch();
    }

    isLoadingMoreDeals = false;
    update();

    if (firstFailure != null) {
      AppMessages.showSnackBar(
        type: ErrorType.error,
        title: 'error'.tr,
        message: firstFailure,
      );
    }
  }

  Future<void> _loadMoreForStatus({
    required String status,
    required Future<dynamic> Function(GetDealsParams params) request,
    required List<Deal> loadedDeals,
    required void Function(String message) onFailure,
    required String fallbackErrorKey,
  }) async {
    if (!(_hasMoreDealsByStatus[status] ?? false)) return;

    final currentPage = _dealPagesByStatus[status] ?? 1;
    final nextPage = currentPage + 1;
    final result = await request(
      GetDealsParams(page: nextPage, perPage: _dealsPerPage),
    );

    result.fold(
      (failure) {
        onFailure(failure.message ?? fallbackErrorKey.tr);
      },
      (paginator) {
        loadedDeals.addAll(paginator.data);
        _dealPagesByStatus[status] = paginator.currentPage;
        _hasMoreDealsByStatus[status] =
            paginator.hasMorePages &&
            paginator.currentPage > currentPage &&
            paginator.data.isNotEmpty;
      },
    );
  }

  void onSearchChanged(String value) {
    searchQuery = value.trim();
    _applySearch();
    update();
  }

  void toggleEmojiPicker() {
    showEmojiPicker = !showEmojiPicker;
    update();
  }

  void hideEmojiPicker() {
    if (!showEmojiPicker) return;
    showEmojiPicker = false;
    update();
  }

  void addEmoji(String emoji) {
    final text = messageController.text;
    final selection = messageController.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    final nextText = text.replaceRange(start, end, emoji);
    messageController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
    update();
  }

  Future<void> pickMediaAttachment() async {
    final picked = await _filePickerService.pickMedia();
    if (picked == null) {
      AppMessages.showSnackBar(
        type: ErrorType.info,
        title: 'info'.tr,
        message: 'لم يتم اختيار ملف.',
      );
      return;
    }
    if (!_validateAttachment(picked)) return;
    selectedAttachment = picked;
    if (_filePickerService.isImageFile(picked)) {
      selectedAttachmentType = 'imageMessage';
    } else if (_filePickerService.isVideoFile(picked)) {
      selectedAttachmentType = 'videoMessage';
    } else {
      selectedAttachmentType = 'documentMessage';
    }
    hideEmojiPicker();
    update();
  }

  Future<void> pickDocumentAttachment() async {
    final picked = await _filePickerService.pickSingleFile();
    if (picked == null) {
      AppMessages.showSnackBar(
        type: ErrorType.info,
        title: 'info'.tr,
        message: 'لم يتم اختيار ملف.',
      );
      return;
    }
    if (!_validateAttachment(picked)) return;
    selectedAttachment = picked;
    selectedAttachmentType = 'documentMessage';
    hideEmojiPicker();
    update();
  }

  Future<void> pickImageAttachment() async {
    final picked = await _filePickerService.pickImage();
    if (picked == null) {
      AppMessages.showSnackBar(
        type: ErrorType.info,
        title: 'info'.tr,
        message: 'لم يتم اختيار صورة.',
      );
      return;
    }
    if (!_validateAttachment(picked)) return;
    selectedAttachment = picked;
    selectedAttachmentType = 'imageMessage';
    hideEmojiPicker();
    update();
  }

  Future<void> pickVideoAttachment() async {
    final picked = await _filePickerService.pickVideo();
    if (picked == null) {
      AppMessages.showSnackBar(
        type: ErrorType.info,
        title: 'info'.tr,
        message: 'لم يتم اختيار فيديو.',
      );
      return;
    }
    if (!_validateAttachment(picked)) return;
    selectedAttachment = picked;
    selectedAttachmentType = 'videoMessage';
    hideEmojiPicker();
    update();
  }

  Future<void> pickAudioAttachment() async {
    final picked = await _filePickerService.pickAudio();
    if (picked == null) {
      AppMessages.showSnackBar(
        type: ErrorType.info,
        title: 'info'.tr,
        message: 'لم يتم اختيار ملف صوتي.',
      );
      return;
    }
    if (!_validateAttachment(picked)) return;
    selectedAttachment = picked;
    selectedAttachmentType = 'audioMessage';
    hideEmojiPicker();
    update();
  }

  void clearAttachment() {
    selectedAttachment = null;
    selectedAttachmentType = null;
    update();
  }

  bool _validateAttachment(File file) {
    final sizeBytes = file.lengthSync();
    const maxBytes = 10 * 1024 * 1024; // 10MB from backend rule
    if (sizeBytes > maxBytes) {
      AppMessages.showSnackBar(
        type: ErrorType.warning,
        title: 'error'.tr,
        message: 'حجم الملف أكبر من 10MB.',
      );
      return false;
    }
    return true;
  }

  Future<void> selectDeal(Deal deal, {bool silentLoading = false}) async {
    if (selectedDeal?.id == deal.id && messages.isNotEmpty) return;

    selectedDeal = deal;
    final cachedMessages = _messagesCache[deal.id];
    if (cachedMessages != null) {
      messages = cachedMessages;
      _currentMessagesPage = _messagesPageCache[deal.id] ?? 1;
      hasOlderMessages = _hasOlderCache[deal.id] ?? false;
      messagesErrorMessage = null;
      update();
      _scrollToBottom();
    }

    await loadMessagesForSelectedDeal(
      showLoader: !silentLoading && cachedMessages == null,
      refresh: cachedMessages != null,
    );
  }

  Future<void> loadMessagesForSelectedDeal({
    bool refresh = false,
    bool showLoader = true,
  }) async {
    final deal = selectedDeal;
    if (deal == null) return;
    final requestId = ++_messagesRequestId;

    if (showLoader) {
      isLoadingMessages = true;
    }
    if (refresh) {
      isRefreshing = true;
    }
    messagesErrorMessage = null;
    update();

    final result = await getDealMessagesUseCase(
      GetDealMessagesParams(
        dealId: deal.id,
        page: 1,
        perPage: _messagesPerPage,
      ),
    );
    if (requestId != _messagesRequestId || selectedDeal?.id != deal.id) {
      return;
    }

    result.fold(
      (failure) {
        messagesErrorMessage = failure.message ?? 'failed_to_load_messages'.tr;
        if (showLoader) {
          isLoadingMessages = false;
        }
        isRefreshing = false;
        update();
        AppMessages.showSnackBar(
          type: ErrorType.error,
          title: 'error'.tr,
          message: messagesErrorMessage,
        );
      },
      (paginator) {
        final loadedMessages = _sortedUniqueMessages(
          List<DealMessage>.from(paginator.data),
        );
        loadedMessages.sort(
          (a, b) => a.messageTimestamp.compareTo(b.messageTimestamp),
        );
        messages = loadedMessages;
        _currentMessagesPage = 1;
        hasOlderMessages = paginator.hasMorePages;
        _messagesCache[deal.id] = loadedMessages;
        _messagesPageCache[deal.id] = 1;
        _hasOlderCache[deal.id] = paginator.hasMorePages;
        if (showLoader) {
          isLoadingMessages = false;
        }
        isRefreshing = false;
        update();
        _scrollToBottom();
      },
    );
  }

  Future<void> loadOlderMessages() async {
    final deal = selectedDeal;
    if (deal == null || !hasOlderMessages || isLoadingOlderMessages) return;

    isLoadingOlderMessages = true;
    update();

    final nextPage = _currentMessagesPage + 1;
    final result = await getDealMessagesUseCase(
      GetDealMessagesParams(
        dealId: deal.id,
        page: nextPage,
        perPage: _messagesPerPage,
      ),
    );

    result.fold(
      (failure) {
        isLoadingOlderMessages = false;
        update();
        AppMessages.showSnackBar(
          type: ErrorType.error,
          title: 'error'.tr,
          message: failure.message ?? 'failed_to_load_messages'.tr,
        );
      },
      (paginator) {
        final older = List<DealMessage>.from(paginator.data);
        final merged = _sortedUniqueMessages([...older, ...messages]);
        messages = merged;
        _currentMessagesPage = nextPage;
        hasOlderMessages = paginator.hasMorePages;
        _messagesCache[deal.id] = merged;
        _messagesPageCache[deal.id] = nextPage;
        _hasOlderCache[deal.id] = paginator.hasMorePages;
        isLoadingOlderMessages = false;
        update();
      },
    );
  }

  Future<void> sendCurrentMessage() async {
    final deal = selectedDeal;
    final text = messageController.text.trim();
    final hasAttachment = selectedAttachment != null;
    if (deal == null || (!hasAttachment && text.isEmpty) || isSendingMessage) {
      return;
    }

    if (!deal.isOpen) {
      AppMessages.showSnackBar(
        type: ErrorType.warning,
        title: 'info'.tr,
        message: 'deal_closed_cannot_send'.tr,
      );
      return;
    }

    isSendingMessage = true;
    update();

    var result = await sendMessageUseCase(
      SendMessageParams(
        dealId: deal.id,
        messageBody: text.isEmpty ? null : text,
        // Backend accepts:
        // conversation,imageMessage,videoMessage,audioMessage,documentMessage,
        // stickerMessage,locationMessage,pollMessage
        messageType: selectedAttachmentType ?? 'conversation',
        fromMe: true,
        mediaPath: selectedAttachment?.path,
      ),
    );

    // Some backends reject custom message_type values.
    final shouldRetryWithoutType = result.fold((failure) {
      final msg = (failure.message ?? '').toLowerCase();
      return msg.contains('نوع الرسالة غير صالح') ||
          msg.contains('message type') ||
          msg.contains('message_type');
    }, (_) => false);

    if (shouldRetryWithoutType) {
      result = await sendMessageUseCase(
        SendMessageParams(
          dealId: deal.id,
          messageBody: text.isEmpty ? null : text,
          messageType: null,
          fromMe: true,
          mediaPath: selectedAttachment?.path,
        ),
      );
    }

    result.fold(
      (failure) {
        isSendingMessage = false;
        update();
        AppMessages.showSnackBar(
          type: ErrorType.error,
          title: 'error'.tr,
          message: failure.message ?? 'failed_to_send_message'.tr,
        );
      },
      (message) {
        messageController.clear();
        clearAttachment();
        messages = _sortedUniqueMessages([...messages, message]);
        _updateSelectedDealLastMessage(message);
        if (selectedDeal != null) {
          _messagesCache[selectedDeal!.id] = messages;
        }
        isSendingMessage = false;
        update();
        _scrollToBottom();
      },
    );
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
        update();
      };
      _reverbService!.onConnectionError = (_) {
        _isReverbConnected = false;
        update();
      };
      _reverbService!.onConnectionClosed = () {
        _isReverbConnected = false;
        update();
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
        print('❌ Error initializing Reverb: $e');
      }
      update();
    }
  }

  static bool _isAdmin(User user) {
    return user.roles.any((role) => role.toLowerCase().contains('admin'));
  }

  void _handleGlobalMessage(Map<String, dynamic> data) {
    try {
      final messageData = data['message'] as Map<String, dynamic>?;
      final dealData = data['deal'] as Map<String, dynamic>?;
      if (messageData == null || dealData == null) return;

      final fromMe = messageData['from_me'] as bool? ?? false;
      final dealId = (dealData['id'] as num?)?.toInt();
      if (dealId == null) return;

      _upsertDealWithMessage(dealData: dealData, messageData: messageData);
      _playIncomingNotificationIfNeeded(messageData, fromMe: fromMe);

      // Add incoming websocket message directly for selected chat.
      if (selectedDeal?.id == dealId && !fromMe) {
        final message = _messageFromReverbPayload(messageData, selectedDeal!);
        messages = _sortedUniqueMessages([...messages, message]);
        _messagesCache[dealId] = messages;
        update();
        _scrollToBottom();
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error handling message.received: $e');
    }
  }

  void _handleDealHistoryUpdated(Map<String, dynamic> data) {
    try {
      final dealData = data['deal'] as Map<String, dynamic>?;
      if (dealData == null) return;

      final dealId = (dealData['id'] as num?)?.toInt();
      if (dealId == null) return;

      final newStatus = dealData['status'] as String?;
      if (newStatus != null && newStatus != 'open') {
        _removeDealById(dealId);
        if (selectedDeal?.id == dealId) {
          selectedDeal = null;
          messages = const [];
        }
        update();
        return;
      }

      final messageData = data['message'] as Map<String, dynamic>?;
      _upsertDealWithMessage(dealData: dealData, messageData: messageData);
      _playIncomingNotificationIfNeeded(messageData, fromMe: false);

      if (selectedDeal?.id == dealId && messageData != null) {
        final message = _messageFromReverbPayload(messageData, selectedDeal!);
        messages = _sortedUniqueMessages([...messages, message]);
        _messagesCache[dealId] = messages;
        update();
        _scrollToBottom();
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error handling deal.history.updated: $e');
    }
  }

  void _upsertDealWithMessage({
    required Map<String, dynamic> dealData,
    Map<String, dynamic>? messageData,
  }) {
    final dealId = (dealData['id'] as num?)?.toInt();
    if (dealId == null) return;

    final existingIndex = allDeals.indexWhere((deal) => deal.id == dealId);
    Deal? baseDeal;

    if (existingIndex >= 0) {
      baseDeal = allDeals[existingIndex];
    } else {
      if (!DealModel.canParseFromJson(dealData)) return;
      try {
        baseDeal = DealModel.fromJson(dealData);
      } catch (_) {
        return;
      }
    }

    if (!baseDeal.isOpen || baseDeal.status != 'open') return;

    final lastMessage = messageData != null
        ? DealLastMessageModel.fromReverbPayload(
            messageData,
            baseDeal.id,
            baseDeal.crmSessionId,
          )
        : baseDeal.lastMessage;

    final updatedDeal = DealModel.fromDealWithLastMessage(
      baseDeal,
      lastMessage,
    );

    if (existingIndex >= 0) {
      final next = List<Deal>.from(allDeals)..removeAt(existingIndex);
      allDeals = [updatedDeal, ...next];
    } else {
      allDeals = [updatedDeal, ...allDeals];
    }

    if (selectedDeal?.id == updatedDeal.id) {
      selectedDeal = updatedDeal;
    }

    _sortDealsByLatestMessage();
    _applySearch();
    update();
  }

  void _removeDealById(int dealId) {
    allDeals = allDeals.where((deal) => deal.id != dealId).toList();
    filteredDeals = filteredDeals.where((deal) => deal.id != dealId).toList();
  }

  DealMessage _messageFromReverbPayload(
    Map<String, dynamic> payload,
    Deal deal,
  ) {
    final timestamp =
        (payload['timestamp'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final messageId =
        payload['id'] as String? ??
        payload['message_id'] as String? ??
        'ws_${timestamp}_${deal.id}';

    final createdAt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final crmSession =
        deal.crmSession ??
        CrmSession(
          id: deal.crmSessionId,
          sessionId: '',
          userId: deal.userId,
          contactGroupId: 0,
          sessionName: null,
          phoneNumber: null,
          apiKey: '',
          status: 'active',
          createdAt: createdAt,
          updatedAt: DateTime.now(),
        );

    return DealMessage(
      id: ((payload['db_id'] as num?)?.toInt()) ?? 0,
      dealId: deal.id,
      crmSessionId: deal.crmSessionId,
      messageId: messageId,
      fromMe: payload['from_me'] as bool? ?? false,
      isAutoWelcome: false,
      isWorkflowMessage: false,
      remoteJid: (payload['remote_jid'] as String?) ?? '',
      senderPn: payload['sender_pn'] as String?,
      cleanedSenderPn: (payload['cleaned_sender_pn'] as String?) ?? '',
      senderLid: payload['sender_lid'] as String?,
      addressingMode: payload['addressing_mode'] as String?,
      messageTimestamp: timestamp,
      pushName: payload['push_name'] as String?,
      broadcast: false,
      status: (payload['status'] as num?)?.toInt(),
      editedAt: null,
      messageType: (payload['message_type'] as String?) ?? 'conversation',
      messageTypeDisplay:
          (payload['message_type_display'] as String?) ??
          (payload['message_type'] as String?) ??
          'conversation',
      messageBody: payload['message_body'] as String?,
      verifiedBizName: payload['verified_biz_name'] as String?,
      hasMediaContent:
          payload['has_media'] as bool? ??
          payload['has_media_content'] as bool? ??
          false,
      mediaUrl: payload['media_url'] as String?,
      mediaType: payload['media_type'] as String?,
      mediaFileSha256: payload['media_file_sha256'] as String?,
      mediaFileLength: (payload['media_file_length'] as num?)?.toInt(),
      mediaHeight: (payload['media_height'] as num?)?.toInt(),
      mediaWidth: (payload['media_width'] as num?)?.toInt(),
      pollData: payload['poll_data'],
      contextInfo: payload['quoted_message'],
      crmSession: crmSession,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  void _updateSelectedDealLastMessage(DealMessage message) {
    final currentSelected = selectedDeal;
    if (currentSelected == null || currentSelected.id != message.dealId) return;

    final lastMessage = DealLastMessageModel.fromReverbPayload(
      {
        'id': message.messageId,
        'db_id': message.id,
        'from_me': message.fromMe,
        'message_type': message.messageType,
        'message_type_display': message.messageTypeDisplay,
        'message_body': message.messageBody,
        'timestamp': message.messageTimestamp,
        'has_media_content': message.hasMediaContent,
        'media_url': message.mediaUrl,
        'media_type': message.mediaType,
      },
      currentSelected.id,
      currentSelected.crmSessionId,
    );

    final updated = DealModel.fromDealWithLastMessage(
      currentSelected,
      lastMessage,
    );
    selectedDeal = updated;
    final idx = allDeals.indexWhere((deal) => deal.id == updated.id);
    if (idx >= 0) {
      final next = List<Deal>.from(allDeals)..removeAt(idx);
      allDeals = [updated, ...next];
      _sortDealsByLatestMessage();
      _applySearch();
    }
  }

  void _sortDealsByLatestMessage() {
    final sorted = List<Deal>.from(allDeals)
      ..sort((a, b) {
        final aTs = a.lastMessage?.messageTimestamp ?? 0;
        final bTs = b.lastMessage?.messageTimestamp ?? 0;
        return bTs.compareTo(aTs);
      });
    allDeals = sorted;
  }

  void _playIncomingNotificationIfNeeded(
    Map<String, dynamic>? messageData, {
    required bool fromMe,
  }) {
    if (fromMe || messageData == null) return;

    final rawMessageId =
        messageData['id'] as String? ?? messageData['message_id'] as String?;
    final rawTimestamp = (messageData['timestamp'] as num?)?.toInt();
    final uniqueKey =
        rawMessageId ?? (rawTimestamp != null ? 'ts_$rawTimestamp' : null);
    if (uniqueKey == null) return;
    if (_playedNotificationMessageIds.contains(uniqueKey)) return;
    _playedNotificationMessageIds.add(uniqueKey);
    if (_playedNotificationMessageIds.length > 200) {
      _playedNotificationMessageIds.remove(_playedNotificationMessageIds.first);
    }

    _playNotificationSound();
  }

  Future<void> _playNotificationSound() async {
    try {
      await _notificationPlayer?.play(AssetSource('sound/notifi.wav'));
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Notification sound failed: $e');
      }
    }
  }

  List<Deal> _deduplicateDeals(List<Deal> deals) {
    final map = <int, Deal>{};
    for (final deal in deals) {
      map[deal.id] = deal;
    }
    return map.values.toList();
  }

  void _applySearch() {
    if (searchQuery.isEmpty) {
      filteredDeals = List<Deal>.from(allDeals);
      return;
    }

    final q = searchQuery.toLowerCase();
    filteredDeals = allDeals.where((deal) {
      final name = (deal.contactName ?? '').toLowerCase();
      final phone = (deal.contactPhone ?? '').toLowerCase();
      final title = (deal.title ?? '').toLowerCase();
      return name.contains(q) || phone.contains(q) || title.contains(q);
    }).toList();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!messagesScrollController.hasClients) return;
      messagesScrollController.animateTo(
        messagesScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  List<DealMessage> _sortedUniqueMessages(List<DealMessage> source) {
    final map = <String, DealMessage>{};
    for (final message in source) {
      map[message.messageId] = message;
    }
    final list = map.values.toList();
    list.sort((a, b) => a.messageTimestamp.compareTo(b.messageTimestamp));
    return list;
  }

  void _onMessagesScroll() {
    if (!messagesScrollController.hasClients) return;
    final position = messagesScrollController.position;
    if (position.pixels <= 80) {
      loadOlderMessages();
    }
  }
}

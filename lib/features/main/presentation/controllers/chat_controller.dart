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
import 'package:alma_desktop/features/main/domain/entities/company_location.dart';
import 'package:alma_desktop/features/main/domain/entities/crm_session.dart';
import 'package:alma_desktop/features/main/domain/entities/deal_message.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_deal_messages_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_lost_deals_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_open_deals_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_won_deals_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_deals_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/get_company_locations_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/send_message_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/update_message_use_case.dart';
import 'package:alma_desktop/features/main/domain/usecases/delete_message_use_case.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:alma_desktop/core/errors/failures.dart';

class ChatController extends GetxController {
  ChatController({
    required this.getOpenDealsUseCase,
    required this.getWonDealsUseCase,
    required this.getLostDealsUseCase,
    required this.getDealMessagesUseCase,
    required this.sendMessageUseCase,
    required this.updateMessageUseCase,
    required this.deleteMessageUseCase,
    required this.getCompanyLocationsUseCase,
  });

  final GetOpenDealsUseCase getOpenDealsUseCase;
  final GetWonDealsUseCase getWonDealsUseCase;
  final GetLostDealsUseCase getLostDealsUseCase;
  final GetDealMessagesUseCase getDealMessagesUseCase;
  final SendMessageUseCase sendMessageUseCase;
  final UpdateMessageUseCase updateMessageUseCase;
  final DeleteMessageUseCase deleteMessageUseCase;
  final GetCompanyLocationsUseCase getCompanyLocationsUseCase;
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
  bool isUpdatingMessage = false;
  int? deletingMessageId;
  bool isLoadingCompanyLocations = false;
  String? companyLocationsErrorMessage;

  List<Deal> allDeals = const [];
  List<Deal> filteredDeals = const [];
  List<DealMessage> messages = const [];
  List<CompanyLocation> companyLocations = const [];

  String searchQuery = '';
  Deal? selectedDeal;
  DealMessage? editingMessage;
  List<File> selectedAttachments = const [];
  String? dealsErrorMessage;
  String? messagesErrorMessage;
  DateTime? _lastDealsLoadedAt;
  int _openDealsPage = 1;
  bool _hasMoreOpenDeals = false;
  int _messagesRequestId = 0;
  int _currentMessagesPage = 1;
  ReverbService? _reverbService;
  AudioPlayer? _notificationPlayer;
  bool _isReverbConnected = false;
  final List<String> _subscribedChannelNames = <String>[];
  final Set<String> _playedNotificationMessageIds = <String>{};
  final Map<int, int> _unreadCountByDealId = <int, int>{};
  final Set<int> _newDealIds = <int>{};

  final Map<int, List<DealMessage>> _messagesCache = <int, List<DealMessage>>{};
  final Map<int, int> _messagesPageCache = <int, int>{};
  final Map<int, bool> _hasOlderCache = <int, bool>{};
  bool get isReverbConnected => _isReverbConnected;
  int unreadCountForDeal(int dealId) => _unreadCountByDealId[dealId] ?? 0;
  bool hasUnreadForDeal(int dealId) => unreadCountForDeal(dealId) > 0;
  bool isNewDeal(int dealId) => _newDealIds.contains(dealId);

  @override
  void onInit() {
    super.onInit();
    if (!Platform.isWindows) {
      _notificationPlayer = AudioPlayer();
    }
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
    _reverbService?.dispose();
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
    final result = await getOpenDealsUseCase(params);

    final loadedDeals = <Deal>[];
    String? firstFailure;

    result.fold(
      (failure) {
        firstFailure = failure.message ?? 'failed_to_load_open_deals'.tr;
        _openDealsPage = 1;
        _hasMoreOpenDeals = false;
      },
      (paginator) {
        loadedDeals.addAll(paginator.data);
        _openDealsPage = paginator.currentPage;
        _hasMoreOpenDeals = paginator.hasMorePages;
      },
    );

    final deduplicated = _deduplicateDeals(loadedDeals);
    deduplicated.sort((a, b) {
      final aTs = _dealOrderingTimestamp(a);
      final bTs = _dealOrderingTimestamp(b);
      return bTs.compareTo(aTs);
    });

    allDeals = deduplicated;
    _lastDealsLoadedAt = DateTime.now();

    // Keep the currently opened chat pinned in state even if it is not in the
    // first fetched page (pagination), so realtime updates don't force-reset it.
    if (selectedDeal != null &&
        !allDeals.any((deal) => deal.id == selectedDeal!.id)) {
      allDeals = [selectedDeal!, ...allDeals];
      _sortDealsByLatestMessage();
    }

    _applySearch();

    if (selectedDeal == null && filteredDeals.isNotEmpty) {
      await selectDeal(filteredDeals.first, silentLoading: true);
    } else if (selectedDeal != null && !refresh) {
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

  bool get hasMoreDeals => _hasMoreOpenDeals;

  Future<void> loadMoreDeals() async {
    if (isLoadingDeals || isRefreshing || isLoadingMoreDeals || !hasMoreDeals) {
      return;
    }

    isLoadingMoreDeals = true;
    update();

    final loadedDeals = <Deal>[];
    String? firstFailure;

    if (_hasMoreOpenDeals) {
      final nextPage = _openDealsPage + 1;
      final result = await getOpenDealsUseCase(
        GetDealsParams(page: nextPage, perPage: _dealsPerPage),
      );
      result.fold(
        (failure) {
          firstFailure = failure.message ?? 'failed_to_load_open_deals'.tr;
        },
        (paginator) {
          loadedDeals.addAll(paginator.data);
          _openDealsPage = paginator.currentPage;
          _hasMoreOpenDeals =
              paginator.hasMorePages &&
              paginator.currentPage > nextPage - 1 &&
              paginator.data.isNotEmpty;
        },
      );
    }

    if (loadedDeals.isNotEmpty) {
      final merged = _deduplicateDeals([...allDeals, ...loadedDeals]);
      merged.sort((a, b) {
        final aTs = _dealOrderingTimestamp(a);
        final bTs = _dealOrderingTimestamp(b);
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
    final picked = await _filePickerService.pickMultipleMedia();
    if (picked == null || picked.isEmpty) {
      AppMessages.showSnackBar(
        type: ErrorType.info,
        title: 'info'.tr,
        message: 'لم يتم اختيار ملف.',
      );
      return;
    }
    _setSelectedAttachments(picked);
    hideEmojiPicker();
    update();
  }

  Future<void> pickDocumentAttachment() async {
    final picked = await _filePickerService.pickMultipleFiles();
    if (picked == null || picked.isEmpty) {
      AppMessages.showSnackBar(
        type: ErrorType.info,
        title: 'info'.tr,
        message: 'لم يتم اختيار ملف.',
      );
      return;
    }
    _setSelectedAttachments(picked);
    hideEmojiPicker();
    update();
  }

  Future<void> pickImageAttachment() async {
    final picked = await _filePickerService.pickMultipleImages();
    if (picked == null || picked.isEmpty) {
      AppMessages.showSnackBar(
        type: ErrorType.info,
        title: 'info'.tr,
        message: 'لم يتم اختيار صورة.',
      );
      return;
    }
    _setSelectedAttachments(picked);
    hideEmojiPicker();
    update();
  }

  Future<void> pickImageFromClipboard() async {
    Uint8List? imageBytes;
    try {
      imageBytes = await Pasteboard.image;
    } catch (_) {
      AppMessages.showSnackBar(
        type: ErrorType.warning,
        title: 'error'.tr,
        message: 'تعذر قراءة الصورة من الحافظة.',
      );
      return;
    }

    if (imageBytes == null || imageBytes.isEmpty) {
      return;
    }

    try {
      final tempPath =
          '${Directory.systemTemp.path}${Platform.pathSeparator}alma_clip_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(tempPath);
      await file.writeAsBytes(imageBytes, flush: true);
      if (!_validateAttachment(file)) return;
      _setSelectedAttachments([file]);
      hideEmojiPicker();
      update();
    } catch (_) {
      AppMessages.showSnackBar(
        type: ErrorType.error,
        title: 'error'.tr,
        message: 'فشل تجهيز الصورة المُلصقة.',
      );
    }
  }

  Future<void> pickVideoAttachment() async {
    final picked = await _filePickerService.pickMultipleVideos();
    if (picked == null || picked.isEmpty) {
      AppMessages.showSnackBar(
        type: ErrorType.info,
        title: 'info'.tr,
        message: 'لم يتم اختيار فيديو.',
      );
      return;
    }
    _setSelectedAttachments(picked);
    hideEmojiPicker();
    update();
  }

  Future<void> pickAudioAttachment() async {
    final picked = await _filePickerService.pickMultipleAudio();
    if (picked == null || picked.isEmpty) {
      AppMessages.showSnackBar(
        type: ErrorType.info,
        title: 'info'.tr,
        message: 'لم يتم اختيار ملف صوتي.',
      );
      return;
    }
    _setSelectedAttachments(picked);
    hideEmojiPicker();
    update();
  }

  void clearAttachment() {
    selectedAttachments = const [];
    update();
  }

  void removeAttachmentAt(int index) {
    if (index < 0 || index >= selectedAttachments.length) return;
    final next = List<File>.from(selectedAttachments)..removeAt(index);
    selectedAttachments = next;
    update();
  }

  void _setSelectedAttachments(List<File> files) {
    final valid = <File>[];
    for (final file in files) {
      if (_validateAttachment(file)) {
        valid.add(file);
      }
    }
    selectedAttachments = valid;
  }

  bool isImageAttachment(File file) {
    return _filePickerService.isImageFile(file);
  }

  String _attachmentTypeFor(File file) {
    if (_filePickerService.isImageFile(file)) return 'imageMessage';
    if (_filePickerService.isVideoFile(file)) return 'videoMessage';
    final extension = _filePickerService.getFileExtension(file);
    if (['mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a'].contains(extension)) {
      return 'audioMessage';
    }
    return 'documentMessage';
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
    if (selectedDeal?.id == deal.id && messages.isNotEmpty) {
      _markDealAsRead(deal.id);
      update();
      return;
    }

    _upsertDealLocally(deal);
    selectedDeal = deal;
    _markDealAsRead(deal.id);
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
    if (editingMessage != null) {
      await _updateCurrentMessage(text);
      return;
    }
    final hasAttachment = selectedAttachments.isNotEmpty;
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

    final attachmentsToSend = List<File>.from(selectedAttachments);
    final sentMessages = <DealMessage>[];

    if (attachmentsToSend.isEmpty) {
      final result = await _sendMessageWithOptionalRetry(
        dealId: deal.id,
        messageBody: text.isEmpty ? null : text,
        messageType: 'conversation',
        mediaPath: null,
      );
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
      return;
    }

    for (var i = 0; i < attachmentsToSend.length; i++) {
      final file = attachmentsToSend[i];
      final messageBody = i == 0 && text.isNotEmpty ? text : null;
      final result = await _sendMessageWithOptionalRetry(
        dealId: deal.id,
        messageBody: messageBody,
        messageType: _attachmentTypeFor(file),
        mediaPath: file.path,
      );
      final failed = result.fold((failure) => failure, (_) => null);
      if (failed != null) {
        isSendingMessage = false;
        update();
        AppMessages.showSnackBar(
          type: ErrorType.error,
          title: 'error'.tr,
          message: failed.message ?? 'failed_to_send_message'.tr,
        );
        return;
      }
      final sent = result.fold<DealMessage?>((_) => null, (message) => message);
      if (sent != null) {
        sentMessages.add(sent);
      }
    }

    messageController.clear();
    clearAttachment();
    if (sentMessages.isNotEmpty) {
      messages = _sortedUniqueMessages([...messages, ...sentMessages]);
      _updateSelectedDealLastMessage(sentMessages.last);
      if (selectedDeal != null) {
        _messagesCache[selectedDeal!.id] = messages;
      }
    }
    isSendingMessage = false;
    update();
    _scrollToBottom();
  }

  Future<Either<Failure, DealMessage>> _sendMessageWithOptionalRetry({
    required int dealId,
    required String? messageBody,
    required String? messageType,
    required String? mediaPath,
    int? locationId,
  }) async {
    var result = await sendMessageUseCase(
      SendMessageParams(
        dealId: dealId,
        messageBody: messageBody,
        // Backend accepts:
        // conversation,imageMessage,videoMessage,audioMessage,documentMessage,
        // stickerMessage,locationMessage,pollMessage
        messageType: messageType,
        fromMe: true,
        mediaPath: mediaPath,
        locationId: locationId,
      ),
    );

    final shouldRetryWithoutType = result.fold((failure) {
      final msg = (failure.message ?? '').toLowerCase();
      return msg.contains('نوع الرسالة غير صالح') ||
          msg.contains('message type') ||
          msg.contains('message_type');
    }, (_) => false);

    if (shouldRetryWithoutType) {
      result = await sendMessageUseCase(
        SendMessageParams(
          dealId: dealId,
          messageBody: messageBody,
          messageType: null,
          fromMe: true,
          mediaPath: mediaPath,
          locationId: locationId,
        ),
      );
    }
    return result;
  }

  Future<void> loadCompanyLocations({bool force = false}) async {
    if (isLoadingCompanyLocations) return;
    if (!force && companyLocations.isNotEmpty) return;

    isLoadingCompanyLocations = true;
    companyLocationsErrorMessage = null;
    update();

    final result = await getCompanyLocationsUseCase(
      const GetCompanyLocationsParams(activeOnly: true),
    );

    result.fold(
      (failure) {
        companyLocationsErrorMessage =
            failure.message ?? 'failed_to_load_locations'.tr;
        isLoadingCompanyLocations = false;
        update();
        AppMessages.showSnackBar(
          type: ErrorType.error,
          title: 'error'.tr,
          message: companyLocationsErrorMessage,
        );
      },
      (locations) {
        companyLocations = locations;
        isLoadingCompanyLocations = false;
        update();
      },
    );
  }

  Future<void> sendLocationMessage(int locationId) async {
    final deal = selectedDeal;
    if (deal == null || isSendingMessage) return;
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

    final result = await _sendMessageWithOptionalRetry(
      dealId: deal.id,
      messageBody: null,
      messageType: null,
      mediaPath: null,
      locationId: locationId,
    );

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

  void startEditingMessage(DealMessage message) {
    if (!message.fromMe) return;
    editingMessage = message;
    messageController.text = message.messageBody ?? '';
    messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: messageController.text.length),
    );
    hideEmojiPicker();
    clearAttachment();
    update();
  }

  void cancelEditingMessage() {
    editingMessage = null;
    messageController.clear();
    update();
  }

  Future<void> _updateCurrentMessage(String text) async {
    final message = editingMessage;
    if (message == null || isUpdatingMessage) return;
    if (text.isEmpty) {
      AppMessages.showSnackBar(
        type: ErrorType.warning,
        title: 'info'.tr,
        message: 'message_text_required'.tr,
      );
      return;
    }

    isUpdatingMessage = true;
    update();

    final result = await updateMessageUseCase(
      UpdateMessageParams(messageId: message.id, messageBody: text),
    );

    result.fold(
      (failure) {
        isUpdatingMessage = false;
        update();
        AppMessages.showSnackBar(
          type: ErrorType.error,
          title: 'error'.tr,
          message: failure.message ?? 'failed_to_update_message'.tr,
        );
      },
      (updatedMessage) {
        _replaceMessageInState(updatedMessage);
        editingMessage = null;
        messageController.clear();
        isUpdatingMessage = false;
        update();
      },
    );
  }

  Future<void> deleteMessage(DealMessage message) async {
    if (deletingMessageId != null || !message.fromMe) return;
    deletingMessageId = message.id;
    update();
    final result = await deleteMessageUseCase(
      DeleteMessageParams(messageId: message.id),
    );
    result.fold(
      (failure) {
        deletingMessageId = null;
        update();
        AppMessages.showSnackBar(
          type: ErrorType.error,
          title: 'error'.tr,
          message: failure.message ?? 'failed_to_delete_message'.tr,
        );
      },
      (_) {
        if (editingMessage?.id == message.id) {
          editingMessage = null;
          messageController.clear();
        }
        _removeMessageFromState(message);
        deletingMessageId = null;
        update();
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

      final upserted = _upsertDealWithMessage(
        dealData: dealData,
        messageData: messageData,
      );
      _playIncomingNotificationIfNeeded(messageData, fromMe: fromMe);
      if (!upserted) {
        unawaited(loadDeals(refresh: true));
      }
      if (!fromMe && selectedDeal?.id != dealId) {
        _incrementUnreadForDeal(dealId);
      }

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
      final actionType = (data['action_type'] as String?)?.toLowerCase();
      final wasKnownDeal = allDeals.any((deal) => deal.id == dealId);

      final newStatus = dealData['status'] as String?;
      if (newStatus != null && newStatus != 'open') {
        _removeDealById(dealId);
        if (selectedDeal?.id == dealId) {
          selectedDeal = null;
          messages = const [];
        }
        _unreadCountByDealId.remove(dealId);
        _newDealIds.remove(dealId);
        update();
        return;
      }

      final messageData = data['message'] as Map<String, dynamic>?;
      final upserted = _upsertDealWithMessage(
        dealData: dealData,
        messageData: messageData,
      );
      _playIncomingNotificationIfNeeded(messageData, fromMe: false);

      if (selectedDeal?.id == dealId && messageData != null) {
        final message = _messageFromReverbPayload(messageData, selectedDeal!);
        messages = _sortedUniqueMessages([...messages, message]);
        _messagesCache[dealId] = messages;
        _markDealAsRead(dealId);
        update();
        _scrollToBottom();
      }

      if (actionType == 'new' && !wasKnownDeal) {
        _newDealIds.add(dealId);
        if (!upserted) {
          unawaited(loadDeals(refresh: true));
        }
        AppMessages.showSnackBar(
          type: ErrorType.info,
          title: 'CRM',
          message: 'new_deal_received'.tr,
        );
        _playNotificationSound();
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error handling deal.history.updated: $e');
    }
  }

  bool _upsertDealWithMessage({
    required Map<String, dynamic> dealData,
    Map<String, dynamic>? messageData,
  }) {
    final dealId = (dealData['id'] as num?)?.toInt();
    if (dealId == null) return false;

    final existingIndex = allDeals.indexWhere((deal) => deal.id == dealId);
    Deal? baseDeal;

    if (existingIndex >= 0) {
      baseDeal = allDeals[existingIndex];
    } else if (selectedDeal?.id == dealId) {
      // Selected chat may be outside the loaded page list.
      baseDeal = selectedDeal;
    } else {
      if (!DealModel.canParseFromJson(dealData)) return false;
      try {
        baseDeal = DealModel.fromJson(dealData);
      } catch (_) {
        return false;
      }
    }

    if (baseDeal == null) return false;

    if (!baseDeal.isOpen || baseDeal.status != 'open') return false;

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
    return true;
  }

  void _removeDealById(int dealId) {
    allDeals = allDeals.where((deal) => deal.id != dealId).toList();
    filteredDeals = filteredDeals.where((deal) => deal.id != dealId).toList();
    _unreadCountByDealId.remove(dealId);
    _newDealIds.remove(dealId);
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

    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      _normalizeUnixToMillis(timestamp),
    );
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

  void _replaceMessageInState(DealMessage updatedMessage) {
    final next = List<DealMessage>.from(messages);
    final idx = next.indexWhere((m) => m.id == updatedMessage.id);
    if (idx >= 0) {
      next[idx] = updatedMessage;
      messages = _sortedUniqueMessages(next);
      if (selectedDeal != null) {
        _messagesCache[selectedDeal!.id] = messages;
      }
      _refreshSelectedDealLastMessageFromMessages();
    }
  }

  void _removeMessageFromState(DealMessage message) {
    messages = messages.where((m) => m.id != message.id).toList();
    if (selectedDeal != null) {
      _messagesCache[selectedDeal!.id] = messages;
    }
    _refreshSelectedDealLastMessageFromMessages();
  }

  void _refreshSelectedDealLastMessageFromMessages() {
    final currentSelected = selectedDeal;
    if (currentSelected == null) return;
    if (messages.isEmpty) return;
    final latest = messages.last;
    _updateSelectedDealLastMessage(latest);
  }

  void _sortDealsByLatestMessage() {
    final sorted = List<Deal>.from(allDeals)
      ..sort((a, b) {
        final aTs = _dealOrderingTimestamp(a);
        final bTs = _dealOrderingTimestamp(b);
        return bTs.compareTo(aTs);
      });
    allDeals = sorted;
  }

  int _dealOrderingTimestamp(Deal deal) {
    return deal.lastMessage?.messageTimestamp ??
        deal.createdAt.millisecondsSinceEpoch ~/ 1000;
  }

  void _incrementUnreadForDeal(int dealId) {
    _unreadCountByDealId[dealId] = unreadCountForDeal(dealId) + 1;
  }

  void _markDealAsRead(int dealId) {
    _unreadCountByDealId.remove(dealId);
    _newDealIds.remove(dealId);
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
    if (Platform.isWindows) return;
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

  void _upsertDealLocally(Deal deal) {
    final existingIndex = allDeals.indexWhere((item) => item.id == deal.id);
    if (existingIndex >= 0) {
      final next = List<Deal>.from(allDeals)..removeAt(existingIndex);
      allDeals = [deal, ...next];
    } else {
      allDeals = [deal, ...allDeals];
    }
    _sortDealsByLatestMessage();
    _applySearch();
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

  int _normalizeUnixToMillis(int rawTimestamp) {
    if (rawTimestamp <= 0) return 0;
    // Some payloads arrive in seconds and others in milliseconds.
    return rawTimestamp >= 1000000000000 ? rawTimestamp : rawTimestamp * 1000;
  }
}

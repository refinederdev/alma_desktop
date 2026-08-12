import 'dart:async';
import 'dart:io';

import 'package:alma_desktop/core/config/app_config.dart';
import 'package:alma_desktop/core/errors/app_messages.dart';
import 'package:alma_desktop/core/errors/failures.dart';
import 'package:alma_desktop/core/services/reverb_service/reverb_service.dart';
import 'package:alma_desktop/core/usecases/usecase.dart';
import 'package:alma_desktop/features/calls/data/models/whatsapp_call_model.dart';
import 'package:alma_desktop/features/calls/domain/entities/call_event.dart';
import 'package:alma_desktop/features/calls/domain/entities/call_session.dart';
import 'package:alma_desktop/features/calls/domain/entities/call_sessions_response.dart';
import 'package:alma_desktop/features/calls/domain/entities/ice_server.dart';
import 'package:alma_desktop/features/calls/domain/entities/whatsapp_call.dart';
import 'package:alma_desktop/features/calls/domain/usecases/calls_use_cases.dart';
import 'package:alma_desktop/features/calls/presentation/widgets/active_call_dialog.dart';
import 'package:alma_desktop/features/calls/presentation/widgets/incoming_call_dialog.dart';
import 'package:alma_desktop/features/calls/services/whatsapp_webrtc_service.dart';
import 'package:alma_desktop/features/global/presentation/controllers/global_controller.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// المراحل الداخلية للمكالمة على الجهاز.
enum CallUiPhase {
  idle,
  ringingIncoming,
  outgoingDialing, // ينشئ الـ offer / ينتظر استجابة Meta
  outgoingConnecting, // وصل sdp_answer ونحن في WebRTC handshake
  outgoingRinging, // هاتف المُتّصل به يرنّ
  inProgress, // مكالمة فعلية
  ended,
}

/// أكواد أخطاء Meta WhatsApp Calling المعروفة.
/// مرجع: <https://developers.facebook.com/docs/whatsapp/cloud-api/support/error-codes>
class CallMetaError {
  static const int callingNotEnabled = 138000;
  static const int receiverUncallable = 138001;
  static const int permissionRequired = 138006;
  static const int callLimitExceeded = 138012;
  static const int legacyPermissionRequired = 131056;
  static const int invalidParameter = 131009;
  static const int callNotActionable = 131055;
  static const int genericParameter = 100;
}

/// مراحل قبول مكالمة واردة — تُستخدم في التشخيص.
enum _AcceptStage { fetchSdp, applyOffer, createAnswer, postAccept }

/// نتيجة محاولة قبول واحدة.
class _AcceptAttemptResult {
  final bool success;
  final _AcceptStage? stage;
  final String message;
  final int? metaCode;

  const _AcceptAttemptResult._({
    required this.success,
    this.stage,
    required this.message,
    this.metaCode,
  });

  factory _AcceptAttemptResult.success() =>
      const _AcceptAttemptResult._(success: true, message: '');

  factory _AcceptAttemptResult.failure({
    required _AcceptStage stage,
    required String message,
    int? metaCode,
  }) => _AcceptAttemptResult._(
    success: false,
    stage: stage,
    message: message,
    metaCode: metaCode,
  );
}

/// نتيجة معالجة Failure قادمة من طبقة الـ API — رسالة جاهزة للعرض + علم
/// "permission required" + كود Meta المُستخرج.
class CallFailureInfo {
  final String message;
  final int? metaCode;
  final bool isPermissionRequired;
  final bool isCallingDisabled;

  const CallFailureInfo({
    required this.message,
    this.metaCode,
    this.isPermissionRequired = false,
    this.isCallingDisabled = false,
  });

  factory CallFailureInfo.fromFailure(Failure failure, String fallback) {
    final raw = (failure.message ?? '').trim();
    final lower = raw.toLowerCase();
    final code = _extractMetaCode(raw);
    final isPerm =
        code == CallMetaError.permissionRequired ||
        code == CallMetaError.legacyPermissionRequired ||
        lower.contains('permission required') ||
        lower.contains('no approved call permission') ||
        lower.contains('call permission') ||
        lower.contains('138006') ||
        lower.contains('131056') ||
        lower.contains('غير مسموح بالاتصال') ||
        lower.contains('لم يمنح');
    return CallFailureInfo(
      message: raw.isNotEmpty ? raw : fallback,
      metaCode: code,
      isPermissionRequired: isPerm,
      isCallingDisabled:
          code == CallMetaError.callingNotEnabled ||
          lower.contains('calling not enabled') ||
          lower.contains('138000'),
    );
  }

  static int? _extractMetaCode(String raw) {
    final m =
        RegExp(r'\((\d{3,6})\)').firstMatch(raw) ??
        RegExp(r'\b(13\d{4})\b').firstMatch(raw);
    if (m != null) {
      final v = int.tryParse(m.group(1)!);
      if (v != null) return v;
    }
    return null;
  }
}

/// متحكّم عام للمكالمات يعيش طوال عمر الجلسة. يستمع لقنوات الـ Reverb
/// لكل CRM session ويعرض حوارات للمكالمة الواردة/النشطة فوق أي شاشة.
class CallController extends GetxController {
  CallController({
    required this.getCallSessionsUseCase,
    required this.getActiveCallUseCase,
    required this.getCallByIdUseCase,
    required this.getCallSdpUseCase,
    required this.getCallingSettingsUseCase,
    required this.setCallingEnabledUseCase,
    required this.initiateCallUseCase,
    required this.acceptCallUseCase,
    required this.rejectCallUseCase,
    required this.terminateCallUseCase,
    required this.checkCallPermissionUseCase,
    required this.requestCallPermissionUseCase,
  });

  static CallController get to => Get.find();

  final GetCallSessionsUseCase getCallSessionsUseCase;
  final GetActiveCallUseCase getActiveCallUseCase;
  final GetCallByIdUseCase getCallByIdUseCase;
  final GetCallSdpUseCase getCallSdpUseCase;
  final GetCallingSettingsUseCase getCallingSettingsUseCase;
  final SetCallingEnabledUseCase setCallingEnabledUseCase;
  final InitiateCallUseCase initiateCallUseCase;
  final AcceptCallUseCase acceptCallUseCase;
  final RejectCallUseCase rejectCallUseCase;
  final TerminateCallUseCase terminateCallUseCase;
  final CheckCallPermissionUseCase checkCallPermissionUseCase;
  final RequestCallPermissionUseCase requestCallPermissionUseCase;

  // ---------- حالة عامة ----------
  CallUiPhase phase = CallUiPhase.idle;
  WhatsAppCall? currentCall;
  CallSession? currentSession;
  Duration callDuration = Duration.zero;
  String? lastError;
  bool isProcessing = false;
  bool isReverbConnected = false;
  bool isInitialized = false;
  bool _isInitializing = false;

  List<CallSession> sessions = const [];
  List<IceServer> iceServers = const [];
  final Map<int, bool?> callingEnabledBySession = <int, bool?>{};
  final Set<int> callingSettingsInFlight = <int>{};

  // ---------- داخلي ----------
  ReverbService? _reverb;
  final List<String> _subscribedChannels = <String>[];
  WhatsAppWebRtcService? _webrtc;
  Timer? _callTimer;
  DateTime? _callStartedAt;
  Timer? _activeCallPollTimer;
  bool _activeCallPollInFlight = false;
  bool _answerApplied = false;

  AudioPlayer? _ringtonePlayer;
  AudioPlayer? _ringbackPlayer;
  bool _ringingNow = false;

  // منع تكرار فتح الحوار
  bool _isDialogOpen = false;

  // ---------- getters ----------
  bool get hasActiveCall =>
      phase != CallUiPhase.idle && phase != CallUiPhase.ended;
  bool get isInbound => currentCall?.isInbound ?? false;
  bool get isOutbound => currentCall?.isOutbound ?? false;
  bool get isMicMuted => _webrtc?.isMuted ?? false;
  String get formattedDuration {
    final h = callDuration.inHours;
    final m = (callDuration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (callDuration.inSeconds % 60).toString().padLeft(2, '0');
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:$m:$s';
    }
    return '$m:$s';
  }

  CallSession? sessionById(int? id) {
    if (id == null) return null;
    try {
      return sessions.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// يستدعى مرة بعد تسجيل الدخول لجلب الجلسات والاشتراك في القنوات.
  Future<void> initialize() async {
    if (isInitialized || _isInitializing) return;
    _isInitializing = true;
    try {
      final token = GlobalController.to.token;
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('☎️ CallController.initialize: no token, skipping');
        }
        return;
      }
      if (kDebugMode) {
        // ignore: avoid_print
        print('☎️ CallController.initialize: fetching sessions...');
      }
      final result = await getCallSessionsUseCase(NoParams());
      result.fold(
        (failure) {
          lastError = failure.message;
          if (kDebugMode) {
            // ignore: avoid_print
            print('❌ getCallSessions failed: ${failure.message}');
          }
        },
        (CallSessionsResponse data) {
          sessions = data.sessions;
          iceServers = data.iceServers;
        },
      );
      if (kDebugMode) {
        // ignore: avoid_print
        print(
          '☎️ Sessions loaded: ${sessions.length} '
          '(${sessions.map((s) => '${s.id}:${s.phoneNumber ?? "?"}').join(", ")})',
        );
        // ignore: avoid_print
        print('☎️ ICE servers: ${iceServers.length}');
      }
      if (sessions.isEmpty) {
        update();
        return;
      }
      await _connectReverb(token);
      isInitialized = true;
      _startActiveCallPoll();
      update();
      unawaited(refreshCallingSettings());
      // إعادة الترطيب — هل هناك مكالمة نشطة الآن؟
      for (final session in sessions) {
        unawaited(rehydrateActiveCall(session.id));
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('❌ CallController.initialize error: $e');
      }
    } finally {
      _isInitializing = false;
    }
  }

  /// يستدعى عند تسجيل الخروج لتنظيف كل الموارد.
  Future<void> shutdown() async {
    await _stopRingtones();
    await _disposeWebRtc();
    _callTimer?.cancel();
    _callTimer = null;
    _activeCallPollTimer?.cancel();
    _activeCallPollTimer = null;
    _callStartedAt = null;
    callDuration = Duration.zero;
    if (_reverb != null) {
      for (final channel in _subscribedChannels) {
        _reverb!.unsubscribeFromChannel(channel);
      }
      _subscribedChannels.clear();
      _reverb!.dispose();
      _reverb = null;
    }
    currentCall = null;
    currentSession = null;
    phase = CallUiPhase.idle;
    isReverbConnected = false;
    isInitialized = false;
    callingEnabledBySession.clear();
    callingSettingsInFlight.clear();
    _closeActiveDialog();
    update();
  }

  bool? isCallingEnabledFor(int? sessionId) {
    if (sessionId == null) return null;
    return callingEnabledBySession[sessionId];
  }

  /// Reads Meta's authoritative state for every available Cloud API number.
  Future<void> refreshCallingSettings([int? onlySessionId]) async {
    final targets = onlySessionId == null
        ? sessions
        : sessions.where((session) => session.id == onlySessionId);

    await Future.wait(
      targets.map((session) async {
        if (!callingSettingsInFlight.add(session.id)) return;
        try {
          final result = await getCallingSettingsUseCase(session.id);
          result.fold((_) => callingEnabledBySession[session.id] = null, (
            settings,
          ) {
            final enabled = settings['calling_enabled'];
            callingEnabledBySession[session.id] = enabled is bool
                ? enabled
                : null;
          });
        } finally {
          callingSettingsInFlight.remove(session.id);
          update();
        }
      }),
    );
  }

  /// Enables calling for a number through the backend/Meta settings API.
  Future<void> enableCalling(int sessionId) async {
    if (!callingSettingsInFlight.add(sessionId)) return;
    update();
    try {
      final result = await setCallingEnabledUseCase(
        SetCallingEnabledParams(sessionId: sessionId, enabled: true),
      );
      result.fold(
        (failure) {
          callingEnabledBySession[sessionId] = false;
          AppMessages.showSnackBar(
            type: ErrorType.error,
            title: 'error'.tr,
            message: failure.message ?? 'failed_to_enable_calling'.tr,
          );
        },
        (_) {
          callingEnabledBySession[sessionId] = true;
          AppMessages.showSnackBar(
            type: ErrorType.success,
            title: 'done'.tr,
            message: 'calling_enabled_successfully'.tr,
          );
        },
      );
    } finally {
      callingSettingsInFlight.remove(sessionId);
      update();
    }
  }

  Future<void> _connectReverb(String token) async {
    _reverb = ReverbService(
      appKey: AppConfig.reverbAppKey,
      host: AppConfig.reverbHost,
      port: AppConfig.reverbPort,
      scheme: AppConfig.reverbScheme,
      apiBaseUrl: AppConfig.baseURL,
      authToken: token,
    );

    _reverb!.onConnected = () {
      isReverbConnected = true;
      update();
    };
    _reverb!.onConnectionError = (_) {
      isReverbConnected = false;
      update();
    };
    _reverb!.onConnectionClosed = () {
      isReverbConnected = false;
      update();
    };
    _reverb!.onCallEvent = _handleReverbCallEvent;

    try {
      if (kDebugMode) {
        // ignore: avoid_print
        print(
          '☎️ Connecting calls Reverb (${AppConfig.reverbScheme}://'
          '${AppConfig.reverbHost}:${AppConfig.reverbPort})',
        );
      }
      await _reverb!.connect();
      await Future<void>.delayed(const Duration(milliseconds: 600));
      for (final session in sessions) {
        try {
          await _reverb!.subscribeToCallSession(session.id);
          _subscribedChannels.add('private-calls.${session.id}');
          if (kDebugMode) {
            // ignore: avoid_print
            print('✅ Subscribed to private-calls.${session.id}');
          }
        } catch (e) {
          if (kDebugMode) {
            // ignore: avoid_print
            print('❌ Failed subscribing to calls session ${session.id}: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('❌ CallController reverb connect error: $e');
      }
    }
  }

  /// تنفيذ لكل حدث `.call.event` قادم.
  void _handleReverbCallEvent(Map<String, dynamic> data, String? channelName) {
    try {
      final type = CallEventType.fromString(data['type'] as String?);
      final callRaw = data['call'];
      final sessionId = (data['session_id'] as num?)?.toInt();
      final timestampRaw = data['timestamp'] as String?;
      DateTime? timestamp;
      if (timestampRaw != null) {
        try {
          timestamp = DateTime.parse(timestampRaw).toLocal();
        } catch (_) {}
      }

      WhatsAppCall? call;
      if (callRaw is Map<String, dynamic>) {
        call = WhatsAppCallModel.fromJson(callRaw);
      } else if (callRaw is Map) {
        call = WhatsAppCallModel.fromJson(Map<String, dynamic>.from(callRaw));
      }

      final event = CallEvent(
        type: type,
        rawType: (data['type'] as String?) ?? 'unknown',
        call: call,
        sessionId: sessionId,
        timestamp: timestamp,
      );
      _dispatchCallEvent(event);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('❌ CallController parsing event error: $e');
      }
    }
  }

  void _dispatchCallEvent(CallEvent event) {
    switch (event.type) {
      case CallEventType.incomingCall:
        _onIncomingCall(event);
        break;
      case CallEventType.callConnected:
        _onCallConnected(event);
        break;
      case CallEventType.callRinging:
        _onCallRinging(event);
        break;
      case CallEventType.callAccepted:
        unawaited(_onCallAccepted(event));
        break;
      case CallEventType.callRejected:
        _onCallRejected(event);
        break;
      case CallEventType.callTerminated:
        _onCallTerminated(event);
        break;
      case CallEventType.unknown:
        break;
    }
  }

  // ====================== أحداث الواتساب ======================

  Future<void> _onIncomingCall(CallEvent event) async {
    final call = event.call;
    if (call == null) return;
    // إذا كانت لدينا مكالمة نشطة أصلاً، تجاهل (Meta لا ترسل عادةً اثنتين معاً)
    if (hasActiveCall && currentCall?.id == call.id) {
      return;
    }
    currentCall = call;
    currentSession = sessionById(call.sessionId);
    phase = CallUiPhase.ringingIncoming;
    lastError = null;
    update();
    _showIncomingDialog();
    unawaited(_playRingtone());
  }

  void _onCallConnected(CallEvent event) {
    if (event.call == null) return;
    currentCall = _mergeCall(event.call!);
    if (phase == CallUiPhase.outgoingDialing) {
      phase = CallUiPhase.outgoingConnecting;
    }
    // `call_connected` يُبَثّ فقط للمكالمات الصادرة (تأكيد Meta للـ offer
    // الذي أرسلناه)، ويحوي sdp_answer من Meta. للمكالمات الواردة نحن من
    // ينشئ الـ answer، لذا لا نطبّق أي answer قادم هنا.
    final isOutboundCall = currentCall?.isOutbound ?? false;
    if (!isOutboundCall) {
      update();
      return;
    }
    final sdpAnswer = event.call!.sdpAnswer ?? currentCall?.sdpAnswer;
    if (sdpAnswer != null && sdpAnswer.isNotEmpty) {
      unawaited(_applyAnswerSafely(sdpAnswer));
    }
    update();
  }

  Future<void> _applyAnswerSafely(String sdp) async {
    if (_answerApplied) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('⚠️ applyAnswer skipped: already applied');
      }
      return;
    }
    try {
      if (_webrtc == null) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('⚠️ applyAnswer skipped: webrtc not initialized');
        }
        return;
      }
      await _webrtc!.applyAnswer(sdp);
      _answerApplied = true;
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('❌ applyAnswer error: $e');
      }
      _showCallError('failed_to_connect_audio'.tr);
      await _finalizeCallTeardown();
    }
  }

  void _onCallRinging(CallEvent event) {
    if (phase == CallUiPhase.outgoingDialing ||
        phase == CallUiPhase.outgoingConnecting) {
      phase = CallUiPhase.outgoingRinging;
      unawaited(_playRingback());
      update();
    }
  }

  Future<void> _onCallAccepted(CallEvent event) async {
    if (event.call != null) {
      currentCall = _mergeCall(event.call!);
    }
    await _stopRingtones();
    await _stopRingback();

    // عند المكالمات الصادرة قد يصل call_accepted قبل تطبيق sdp_answer (إذا
    // فات حدث call_connected). نتحقّق ونُلحق التطبيق قبل تشغيل المؤقّت.
    final c = currentCall;
    final isOutboundCall = c?.isOutbound ?? false;
    if (isOutboundCall) {
      final answer = c?.sdpAnswer;
      if (!_answerApplied && answer != null && answer.isNotEmpty) {
        await _applyAnswerSafely(answer);
      }

      if (!_answerApplied) {
        // لم يصلنا الـ answer بعد — اجلبه قبل البدء.
        if (kDebugMode) {
          // ignore: avoid_print
          print('⚠️ call_accepted arrived before sdp_answer — fetching now');
        }
        final sdpResult = await getCallSdpUseCase(c!.id);
        await sdpResult.fold<Future<void>>((_) async {}, (callWithSdp) async {
          final a = callWithSdp.sdpAnswer;
          if (a != null && a.isNotEmpty) {
            currentCall = (currentCall ?? c).copyWith(sdpAnswer: a);
            await _applyAnswerSafely(a);
          }
        });
      }

      // Do not report an audio call as connected until the remote SDP answer
      // has actually been applied. Polling will retry if Reverb raced ahead.
      if (!_answerApplied) {
        if (_webrtc == null) return;
        phase = CallUiPhase.outgoingConnecting;
        update();
        return;
      }
    }

    phase = CallUiPhase.inProgress;
    _startCallTimer();
    update();
  }

  Future<void> _onCallRejected(CallEvent event) async {
    if (event.call != null) {
      currentCall = _mergeCall(event.call!);
    }
    await _stopRingtones();
    await _stopRingback();
    phase = CallUiPhase.ended;
    AppMessages.showSnackBar(
      type: ErrorType.warning,
      title: 'call'.tr,
      message: 'call_rejected'.tr,
    );
    await _finalizeCallTeardown();
  }

  Future<void> _onCallTerminated(CallEvent event) async {
    if (event.call != null) {
      currentCall = _mergeCall(event.call!);
    }
    await _stopRingtones();
    await _stopRingback();
    phase = CallUiPhase.ended;
    await _finalizeCallTeardown();
  }

  WhatsAppCall _mergeCall(WhatsAppCall incoming) {
    final base = currentCall;
    if (base == null) return incoming;
    return base.copyWith(
      id: incoming.id,
      callId: incoming.callId ?? base.callId,
      direction: incoming.direction,
      status: incoming.status,
      sessionId: incoming.sessionId ?? base.sessionId,
      callerPhone: incoming.callerPhone ?? base.callerPhone,
      calleePhone: incoming.calleePhone ?? base.calleePhone,
      remotePhone: incoming.remotePhone ?? base.remotePhone,
      duration: incoming.duration ?? base.duration,
      durationSeconds: incoming.durationSeconds ?? base.durationSeconds,
      dealId: incoming.dealId ?? base.dealId,
      contactName: incoming.contactName ?? base.contactName,
      sdpOffer: incoming.sdpOffer ?? base.sdpOffer,
      sdpAnswer: incoming.sdpAnswer ?? base.sdpAnswer,
      startedAt: incoming.startedAt ?? base.startedAt,
      endedAt: incoming.endedAt ?? base.endedAt,
      createdAt: incoming.createdAt ?? base.createdAt,
    );
  }

  // ====================== إجراءات المستخدم ======================

  /// قبول مكالمة واردة. ينفّذ الـ WebRTC handshake ويُعيد المحاولة تلقائياً
  /// مرّة واحدة عند خطأ 131009 (offer قديم) كما يوصي توثيق Meta.
  Future<void> acceptIncomingCall() async {
    final call = currentCall;
    if (call == null || isProcessing) return;
    if (phase != CallUiPhase.ringingIncoming) return;

    isProcessing = true;
    phase = CallUiPhase.outgoingConnecting; // UI: Connecting
    update();
    await _stopRingtones();
    switchToActiveDialog();

    try {
      // 1) تهيئة WebRTC (مرة واحدة قبل المحاولات)
      try {
        if (kDebugMode) {
          // ignore: avoid_print
          print('🎤 [accept] Requesting microphone & creating peer...');
        }
        await _ensureWebRtc();
      } catch (e) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('❌ [accept] Microphone/peer setup failed: $e');
        }
        _showCallError('microphone_permission_denied'.tr);
        await _finalizeCallTeardown();
        return;
      }

      // المحاولة الأولى — استخدم الـ offer من الحدث إن وُجد، وإلا اجلبه.
      var attempt = 0;
      bool useFreshOffer = false;
      while (attempt < 2) {
        attempt++;
        final result = await _attemptAccept(
          call.id,
          forceFreshOffer: useFreshOffer,
        );
        if (result.success) {
          if (kDebugMode) {
            // ignore: avoid_print
            print(
              '✅ [accept] Succeeded on attempt $attempt — waiting for '
              'call_accepted event',
            );
          }
          update();
          return;
        }

        // فشل — هل يستحق إعادة المحاولة بـ SDP محدّث؟
        final shouldRetry =
            attempt == 1 &&
            (result.metaCode == CallMetaError.invalidParameter ||
                result.stage == _AcceptStage.applyOffer ||
                result.stage == _AcceptStage.createAnswer);
        if (!shouldRetry) {
          if (kDebugMode) {
            // ignore: avoid_print
            print(
              '❌ [accept] Final failure on attempt $attempt '
              '(stage=${result.stage}, meta=${result.metaCode}): '
              '${result.message}',
            );
          }
          _showCallError(result.message);
          await _finalizeCallTeardown();
          return;
        }

        if (kDebugMode) {
          // ignore: avoid_print
          print(
            '🔁 [accept] Retry with fresh offer '
            '(stage=${result.stage}, meta=${result.metaCode})',
          );
        }
        // أعد تهيئة WebRTC لتجنّب أي حالة عالقة بين المحاولتين
        await _disposeWebRtc();
        _answerApplied = false;
        try {
          await _ensureWebRtc();
        } catch (e) {
          _showCallError('microphone_permission_denied'.tr);
          await _finalizeCallTeardown();
          return;
        }
        useFreshOffer = true;
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('❌ [accept] Unexpected error: $e');
      }
      _showCallError('failed_to_accept_call'.tr);
      await _finalizeCallTeardown();
    } finally {
      isProcessing = false;
      update();
    }
  }

  /// محاولة واحدة لقبول المكالمة. تُرجع نتيجة مفصّلة لتمكين إعادة المحاولة.
  Future<_AcceptAttemptResult> _attemptAccept(
    int callId, {
    required bool forceFreshOffer,
  }) async {
    // (أ) الحصول على الـ offer — إما من الحدث الحالي أو من /sdp.
    String? sdpOffer = forceFreshOffer ? null : currentCall?.sdpOffer;
    if (sdpOffer == null || sdpOffer.isEmpty) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('☎️ [accept] Fetching SDP from /sdp for call $callId...');
      }
      final sdpResult = await getCallSdpUseCase(callId);
      final sdpFailure = sdpResult.fold<CallFailureInfo?>(
        (failure) =>
            CallFailureInfo.fromFailure(failure, 'failed_to_load_sdp'.tr),
        (callWithSdp) {
          sdpOffer = callWithSdp.sdpOffer;
          if (sdpOffer != null && sdpOffer!.isNotEmpty) {
            currentCall = (currentCall ?? callWithSdp).copyWith(
              sdpOffer: sdpOffer,
            );
          }
          return null;
        },
      );
      if (sdpFailure != null) {
        return _AcceptAttemptResult.failure(
          stage: _AcceptStage.fetchSdp,
          message: sdpFailure.message,
          metaCode: sdpFailure.metaCode,
        );
      }
      if (sdpOffer == null || sdpOffer!.isEmpty) {
        return _AcceptAttemptResult.failure(
          stage: _AcceptStage.fetchSdp,
          message: 'failed_to_load_sdp'.tr,
        );
      }
    }

    // (ب) تطبيق الـ offer
    try {
      await _webrtc!.applyOffer(sdpOffer!);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('❌ [accept] applyOffer failed: $e');
      }
      return _AcceptAttemptResult.failure(
        stage: _AcceptStage.applyOffer,
        message: 'invalid_remote_sdp'.tr,
      );
    }

    // (ج) إنشاء الـ answer
    final String sdpAnswer;
    try {
      sdpAnswer = await _webrtc!.createAnswer();
      if (sdpAnswer.isEmpty) {
        return _AcceptAttemptResult.failure(
          stage: _AcceptStage.createAnswer,
          message: 'failed_to_create_answer'.tr,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('❌ [accept] createAnswer failed: $e');
      }
      return _AcceptAttemptResult.failure(
        stage: _AcceptStage.createAnswer,
        message: 'failed_to_create_answer'.tr,
      );
    }

    if (kDebugMode) {
      // ignore: avoid_print
      print(
        '☎️ [accept] POST /accept (call=$callId, '
        'answer length=${sdpAnswer.length})...',
      );
    }

    // (د) إرسال الـ answer
    final acceptResult = await acceptCallUseCase(
      AcceptCallParams(callId: callId, sdpAnswer: sdpAnswer),
    );
    return acceptResult.fold<_AcceptAttemptResult>(
      (failure) {
        final info = CallFailureInfo.fromFailure(
          failure,
          'failed_to_accept_call'.tr,
        );
        return _AcceptAttemptResult.failure(
          stage: _AcceptStage.postAccept,
          message: info.message,
          metaCode: info.metaCode,
        );
      },
      (updated) {
        currentCall = _mergeCall(updated);
        return _AcceptAttemptResult.success();
      },
    );
  }

  /// رفض مكالمة واردة.
  Future<void> rejectIncomingCall() async {
    final call = currentCall;
    if (call == null || isProcessing) return;

    isProcessing = true;
    update();
    await _stopRingtones();

    try {
      final result = await rejectCallUseCase(call.id);
      final rejectFailure = result.fold<CallFailureInfo?>(
        (failure) =>
            CallFailureInfo.fromFailure(failure, 'failed_to_reject_call'.tr),
        (updated) {
          currentCall = _mergeCall(updated);
          return null;
        },
      );
      if (rejectFailure != null) {
        // نتجاهل خطأ الرفض غير الحرج ونغلق محلياً لتجنب إغلاق صامت أسوأ.
        if (kDebugMode) {
          // ignore: avoid_print
          print('❌ reject failed: ${rejectFailure.message}');
        }
      }
      phase = CallUiPhase.ended;
      await _finalizeCallTeardown();
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('❌ rejectIncomingCall error: $e');
      }
      await _finalizeCallTeardown();
    } finally {
      isProcessing = false;
      update();
    }
  }

  /// إنهاء مكالمة جارية أو إلغاء مكالمة صادرة.
  Future<void> hangUp() async {
    final call = currentCall;
    if (call == null || isProcessing) {
      await _finalizeCallTeardown();
      return;
    }
    isProcessing = true;
    update();
    try {
      final result = await terminateCallUseCase(call.id);
      result.fold(
        (failure) {
          // حتى لو فشل إعلام السيرفر، نُغلق محلياً
          if (kDebugMode) {
            // ignore: avoid_print
            print('❌ terminate failed: ${failure.message}');
          }
        },
        (updated) {
          currentCall = _mergeCall(updated);
        },
      );
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('❌ hangUp error: $e');
      }
    } finally {
      isProcessing = false;
      phase = CallUiPhase.ended;
      await _finalizeCallTeardown();
    }
  }

  /// بدء مكالمة صادرة لرقم محدد عبر جلسة معينة.
  Future<void> startOutboundCall({
    required int sessionId,
    required String toPhone,
    String? contactName,
    int? dealId,
  }) async {
    if (hasActiveCall || isProcessing) {
      AppMessages.showSnackBar(
        type: ErrorType.warning,
        title: 'info'.tr,
        message: 'call_already_in_progress'.tr,
      );
      return;
    }
    if (toPhone.trim().isEmpty) {
      AppMessages.showSnackBar(
        type: ErrorType.warning,
        title: 'error'.tr,
        message: 'phone_required'.tr,
      );
      return;
    }
    final normalized = _normalizePhone(toPhone);
    final session = sessionById(sessionId);
    if (session == null) {
      AppMessages.showSnackBar(
        type: ErrorType.error,
        title: 'error'.tr,
        message: 'no_call_session_available'.tr,
      );
      return;
    }
    isProcessing = true;
    currentSession = session;
    phase = CallUiPhase.outgoingDialing;
    lastError = null;
    _answerApplied = false;
    currentCall = WhatsAppCall(
      id: 0,
      direction: 'outbound',
      status: 'pending',
      sessionId: session.id,
      calleePhone: normalized,
      remotePhone: normalized,
      contactName: contactName,
      dealId: dealId,
    );
    update();
    _showActiveDialog();

    try {
      if (callingEnabledBySession[session.id] == false) {
        _showCallError('calling_disabled_hint'.tr);
        await _finalizeCallTeardown();
        return;
      }

      // Avoid creating a microphone/WebRTC session when Meta already knows
      // the customer has not granted outbound calling permission.
      final permissionResult = await checkCallPermissionUseCase(
        CheckCallPermissionParams(sessionId: session.id, userPhone: normalized),
      );
      CallFailureInfo? permissionFailure;
      bool permissionGranted = false;
      permissionResult.fold((failure) {
        permissionFailure = CallFailureInfo.fromFailure(
          failure,
          'failed_to_check_call_permission'.tr,
        );
      }, (permission) => permissionGranted = permission.granted);

      if (permissionFailure != null) {
        if (permissionFailure!.isCallingDisabled) {
          callingEnabledBySession[session.id] = false;
        }
        _showCallError(permissionFailure!.message);
        await _finalizeCallTeardown();
        return;
      }

      if (!permissionGranted) {
        await _handleOutboundFailure(
          info: CallFailureInfo(
            message: 'call_permission_required'.tr,
            metaCode: CallMetaError.permissionRequired,
            isPermissionRequired: true,
          ),
          sessionId: session.id,
          toPhone: normalized,
          contactName: contactName,
          dealId: dealId,
        );
        return;
      }

      await _ensureWebRtc();
      final sdpOffer = await _webrtc!.createOffer();

      final result = await initiateCallUseCase(
        InitiateCallParams(
          sessionId: session.id,
          to: normalized,
          sdpOffer: sdpOffer,
        ),
      );
      final failureInfo = await result.fold<Future<CallFailureInfo?>>(
        (failure) async =>
            CallFailureInfo.fromFailure(failure, 'failed_to_initiate_call'.tr),
        (initiated) async {
          currentCall = _mergeCall(initiated);
          return null;
        },
      );

      if (failureInfo != null) {
        if (failureInfo.isCallingDisabled) {
          callingEnabledBySession[session.id] = false;
        }
        await _handleOutboundFailure(
          info: failureInfo,
          sessionId: session.id,
          toPhone: normalized,
          contactName: contactName,
          dealId: dealId,
        );
        return;
      }
      update();
      // ننتظر call_connected ثم call_accepted عبر Reverb.
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('❌ startOutboundCall error: $e');
      }
      AppMessages.showSnackBar(
        type: ErrorType.error,
        title: 'error'.tr,
        message: 'failed_to_initiate_call'.tr,
      );
      await _finalizeCallTeardown();
    } finally {
      isProcessing = false;
      update();
    }
  }

  Future<void> _handleOutboundFailure({
    required CallFailureInfo info,
    required int sessionId,
    required String toPhone,
    String? contactName,
    int? dealId,
  }) async {
    lastError = info.message;
    await _finalizeCallTeardown();

    if (info.isPermissionRequired) {
      // اقترح إرسال طلب إذن المكالمة التفاعلي. قد يختار العميل إذناً
      // مؤقتاً (7 أيام) أو دائماً.
      final confirm = await Get.dialog<bool>(
        AlertDialog(
          title: Text('call_permission_required'.tr),
          content: Text(
            'call_permission_required_body'.trParams({'phone': toPhone}),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              child: Text('send_permission_request'.tr),
            ),
          ],
        ),
        barrierDismissible: true,
      );
      if (confirm == true) {
        await requestCallingPermission(sessionId: sessionId, toPhone: toPhone);
      }
      return;
    }

    AppMessages.showSnackBar(
      type: ErrorType.error,
      title: 'error'.tr,
      message: info.message,
    );
  }

  /// يرسل قالب "السماح بالمكالمات" للعميل عبر واتساب.
  Future<void> requestCallingPermission({
    required int sessionId,
    required String toPhone,
  }) async {
    final normalized = _normalizePhone(toPhone);
    final result = await requestCallPermissionUseCase(
      RequestCallPermissionParams(sessionId: sessionId, to: normalized),
    );
    result.fold(
      (failure) {
        AppMessages.showSnackBar(
          type: ErrorType.error,
          title: 'error'.tr,
          message: failure.message ?? 'failed_to_send_permission_request'.tr,
        );
      },
      (_) {
        AppMessages.showSnackBar(
          type: ErrorType.success,
          title: 'done'.tr,
          message: 'permission_request_sent'.tr,
        );
      },
    );
  }

  /// إعادة استرداد المكالمة النشطة (مثلاً عند إعادة التشغيل).
  Future<void> rehydrateActiveCall(int sessionId) async {
    if (hasActiveCall) return;
    final result = await getActiveCallUseCase(sessionId);
    result.fold((_) {}, (call) {
      if (call == null) return;
      currentCall = call;
      currentSession = sessionById(call.sessionId ?? sessionId);
      if (call.isInProgress) {
        phase = CallUiPhase.inProgress;
        if (call.startedAt != null) {
          _callStartedAt = call.startedAt;
          _startCallTimer();
        }
      } else if (call.isRinging && call.isInbound) {
        phase = CallUiPhase.ringingIncoming;
        _showIncomingDialog();
        unawaited(_playRingtone());
      }
      update();
    });
  }

  // ====================== Mic / مؤقت ======================

  void toggleMute() {
    final webrtc = _webrtc;
    if (webrtc == null) return;
    webrtc.setMicMuted(!webrtc.isMuted);
    update();
  }

  void _startCallTimer() {
    _callTimer?.cancel();
    _callStartedAt ??= DateTime.now();
    callDuration = DateTime.now().difference(_callStartedAt!);
    update();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_callStartedAt == null) return;
      callDuration = DateTime.now().difference(_callStartedAt!);
      update();
    });
  }

  // ====================== Helpers ======================

  void _showCallError(String message) {
    lastError = message;
    AppMessages.showSnackBar(
      type: ErrorType.error,
      title: 'error'.tr,
      message: message,
    );
  }

  Future<void> _ensureWebRtc() async {
    _webrtc ??= WhatsAppWebRtcService();
    if (iceServers.isEmpty) {
      // افتراضي STUN عام لو ضاعت القائمة
      iceServers = const [
        IceServer(urls: ['stun:stun.l.google.com:19302']),
      ];
    }
    _webrtc!.onConnectionState = (state) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('🔌 WebRTC state: $state');
      }
    };
    await _webrtc!.start(iceServers: iceServers);
  }

  Future<void> _disposeWebRtc() async {
    try {
      await _webrtc?.dispose();
    } catch (_) {}
    _webrtc = null;
  }

  // ====================== Polling احتياطي ======================
  //
  // يُستخدم Reverb كقناة أساسية لاستقبال أحداث المكالمات لحظياً، لكن قد
  // يفشل الاشتراك أو يتأخر الحدث لأسباب شبكية. نُجري polling خفيف كل
  // ~7 ثوانٍ على /whatsapp-calls/active لكل جلسة لاكتشاف أي مكالمة
  // واردة فاتت Reverb. عند وجود مكالمة محلية نشطة نتوقف.

  void _startActiveCallPoll() {
    _activeCallPollTimer?.cancel();
    // فاصل تكيّفي: 3 ثوانٍ أثناء الحالات الحرجة (مكالمة قيد التأسيس) و 8 ثوانٍ
    // عندما لا توجد مكالمة محلية. هذا يضمن سرعة اكتشاف "تم الرد على الهاتف"
    // إذا فات حدث Reverb.
    void schedule() {
      final isCritical =
          phase == CallUiPhase.outgoingDialing ||
          phase == CallUiPhase.outgoingConnecting ||
          phase == CallUiPhase.outgoingRinging;
      final interval = isCritical
          ? const Duration(seconds: 3)
          : const Duration(seconds: 8);
      _activeCallPollTimer = Timer(interval, () async {
        await _pollActiveCallsOnce();
        if (_activeCallPollTimer != null) schedule();
      });
    }

    schedule();
  }

  Future<void> _pollActiveCallsOnce() async {
    if (_activeCallPollInFlight) return;
    if (sessions.isEmpty) return;
    _activeCallPollInFlight = true;
    try {
      // الحالة 1: لدينا مكالمة محلية نشطة — نتأكد فقط من حالتها على السيرفر
      // لمواكبة أي حدث Reverb فاتنا (مثل call_connected بعد ضغط المتصل به).
      final local = currentCall;
      if (local != null && local.id != 0) {
        final result = await getCallByIdUseCase(
          GetCallByIdParams(callId: local.id, includeSdp: true),
        );
        await result.fold<Future<void>>(
          (_) async {},
          (remoteCall) => _reconcileLocalAndRemote(local, remoteCall),
        );
        return;
      }

      // الحالة 2: لا توجد مكالمة محلية — نسأل كل جلسة لاكتشاف مكالمة جديدة.
      for (final session in sessions) {
        if (hasActiveCall) break;
        final result = await getActiveCallUseCase(session.id);
        result.fold((_) {}, (call) {
          if (call == null) return;
          if (call.isInbound &&
              (call.status == 'ringing' || call.status == 'pending')) {
            currentCall = call;
            currentSession = session;
            phase = CallUiPhase.ringingIncoming;
            _showIncomingDialog();
            unawaited(_playRingtone());
            update();
          } else if (call.isInProgress) {
            currentCall = call;
            currentSession = session;
            phase = CallUiPhase.inProgress;
            _startCallTimer();
            _showActiveDialog();
            update();
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('❌ active call poll error: $e');
      }
    } finally {
      _activeCallPollInFlight = false;
    }
  }

  /// يوازن بين الحالة المحلية والمكالمة الفعلية على السيرفر — يلتقط ما فات
  /// من أحداث Reverb (خاصةً call_connected و call_accepted).
  Future<void> _reconcileLocalAndRemote(
    WhatsAppCall local,
    WhatsAppCall remote,
  ) async {
    // فقط نُهتم بنفس المكالمة
    if (remote.id != local.id) return;

    // 1) إذا كانت **صادرة** وعندنا حالة "تتصل/تتوصل" ولم نطبّق الـ answer
    // بعد، نحاول جلب الـ SDP وتطبيقه. (للمكالمات الواردة نحن من ينشئ الـ
    // answer ويرسله، فلا يجب أبداً تطبيق answer قادم من السيرفر).
    final isOutboundLocal = local.isOutbound;
    if (isOutboundLocal &&
        !_answerApplied &&
        (phase == CallUiPhase.outgoingDialing ||
            phase == CallUiPhase.outgoingConnecting ||
            phase == CallUiPhase.outgoingRinging)) {
      final answer = remote.sdpAnswer;
      if (answer != null && answer.isNotEmpty) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('🔄 Poll: applying missed sdp_answer for call ${local.id}');
        }
        currentCall = local.copyWith(sdpAnswer: answer);
        await _applyAnswerSafely(answer);
        update();
      } else {
        // ربما الحقل غير مضمَّن — نطلبه صراحةً.
        final sdpResult = await getCallSdpUseCase(local.id);
        await sdpResult.fold<Future<void>>((_) async {}, (sdpCall) async {
          final a = sdpCall.sdpAnswer;
          if (a != null && a.isNotEmpty) {
            if (kDebugMode) {
              // ignore: avoid_print
              print('🔄 Poll: fetched sdp_answer for call ${local.id}');
            }
            currentCall = (currentCall ?? local).copyWith(sdpAnswer: a);
            await _applyAnswerSafely(a);
            update();
          }
        });
      }
    }

    // 2) السيرفر يعتبرها in_progress ونحن لا — انتقل فوراً لـ inProgress.
    if (remote.isInProgress && phase != CallUiPhase.inProgress) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('🔄 Poll: server says in_progress, transitioning UI');
      }
      currentCall = _mergeCall(remote);
      phase = CallUiPhase.inProgress;
      await _stopRingback();
      await _stopRingtones();
      if (_callStartedAt == null) _startCallTimer();
      update();
    }

    // 3) السيرفر يعتبرها منتهية ونحن لا — أنهِ محلياً.
    if (remote.isTerminated && phase != CallUiPhase.ended) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('🔄 Poll: server says terminated, tearing down');
      }
      currentCall = _mergeCall(remote);
      phase = CallUiPhase.ended;
      await _finalizeCallTeardown();
    }
  }

  Future<void> _finalizeCallTeardown() async {
    _callTimer?.cancel();
    _callTimer = null;
    _callStartedAt = null;
    callDuration = Duration.zero;
    _answerApplied = false;
    await _stopRingtones();
    await _stopRingback();
    await _disposeWebRtc();
    _closeActiveDialog();
    // نظهر شاشة النهاية لثوانٍ بسيطة في حال أردنا لاحقاً عرض خلاصة
    Timer(const Duration(seconds: 1), () {
      currentCall = null;
      currentSession = null;
      phase = CallUiPhase.idle;
      update();
    });
    update();
  }

  // ====================== UI overlays ======================

  void _showIncomingDialog() {
    if (_isDialogOpen) return;
    _isDialogOpen = true;
    Get.dialog(
      const IncomingCallDialog(),
      barrierDismissible: false,
      barrierColor: Colors.black54,
    ).whenComplete(() {
      _isDialogOpen = false;
    });
  }

  void _showActiveDialog() {
    if (_isDialogOpen) return;
    _isDialogOpen = true;
    Get.dialog(
      const ActiveCallDialog(),
      barrierDismissible: false,
      barrierColor: Colors.black54,
    ).whenComplete(() {
      _isDialogOpen = false;
    });
  }

  /// يستخدم بعد قبول المكالمة الواردة لتحويل الحوار من Ringing إلى Active.
  void switchToActiveDialog() {
    _closeActiveDialog();
    _showActiveDialog();
  }

  void _closeActiveDialog() {
    if (Get.isDialogOpen ?? false) {
      try {
        Get.back();
      } catch (_) {}
    }
    _isDialogOpen = false;
  }

  // ====================== Audio (ringtone / ringback) ======================

  Future<void> _playRingtone() async {
    if (_ringingNow) return;
    if (Platform.isWindows) {
      return; // على ويندوز نتجنّب audioplayers خاص بنغمة الواردة
    }
    _ringingNow = true;
    try {
      _ringtonePlayer ??= AudioPlayer();
      await _ringtonePlayer!.setReleaseMode(ReleaseMode.loop);
      await _ringtonePlayer!.play(AssetSource('sound/notifi.wav'));
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('⚠️ ringtone failed: $e');
      }
    }
  }

  Future<void> _stopRingtones() async {
    if (!_ringingNow) return;
    _ringingNow = false;
    try {
      await _ringtonePlayer?.stop();
    } catch (_) {}
  }

  Future<void> _playRingback() async {
    if (Platform.isWindows) return;
    try {
      _ringbackPlayer ??= AudioPlayer();
      await _ringbackPlayer!.setReleaseMode(ReleaseMode.loop);
      await _ringbackPlayer!.play(AssetSource('sound/notifi.wav'));
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('⚠️ ringback failed: $e');
      }
    }
  }

  Future<void> _stopRingback() async {
    try {
      await _ringbackPlayer?.stop();
    } catch (_) {}
  }

  String _normalizePhone(String phone) {
    var n = phone.trim();
    n = n.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (n.startsWith('+')) {
      n = n.substring(1);
    }
    return n;
  }

  @override
  void onClose() {
    shutdown();
    super.onClose();
  }
}

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
  static const int permissionRequired = 131056;
  static const int invalidParameter = 131009;
  static const int callNotActionable = 131055;
  static const int genericParameter = 100;
}

/// نتيجة معالجة Failure قادمة من طبقة الـ API — رسالة جاهزة للعرض + علم
/// "permission required" + كود Meta المُستخرج.
class CallFailureInfo {
  final String message;
  final int? metaCode;
  final bool isPermissionRequired;

  const CallFailureInfo({
    required this.message,
    this.metaCode,
    this.isPermissionRequired = false,
  });

  factory CallFailureInfo.fromFailure(Failure failure, String fallback) {
    final raw = (failure.message ?? '').trim();
    final lower = raw.toLowerCase();
    final code = _extractMetaCode(raw);
    final isPerm = code == CallMetaError.permissionRequired ||
        lower.contains('permission required') ||
        lower.contains('call permission') ||
        lower.contains('131056') ||
        lower.contains('غير مسموح بالاتصال') ||
        lower.contains('لم يمنح');
    return CallFailureInfo(
      message: raw.isNotEmpty ? raw : fallback,
      metaCode: code,
      isPermissionRequired: isPerm,
    );
  }

  static int? _extractMetaCode(String raw) {
    final m = RegExp(r'\((\d{3,6})\)').firstMatch(raw) ??
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
    required this.getCallSdpUseCase,
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
  final GetCallSdpUseCase getCallSdpUseCase;
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

  // ---------- داخلي ----------
  ReverbService? _reverb;
  final List<String> _subscribedChannels = <String>[];
  WhatsAppWebRtcService? _webrtc;
  Timer? _callTimer;
  DateTime? _callStartedAt;
  Timer? _activeCallPollTimer;
  bool _activeCallPollInFlight = false;

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
    _closeActiveDialog();
    update();
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
  void _handleReverbCallEvent(
    Map<String, dynamic> data,
    String? channelName,
  ) {
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
        call = WhatsAppCallModel.fromJson(
          Map<String, dynamic>.from(callRaw),
        );
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
        _onCallAccepted(event);
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
    // إن لم نكن قد بدأنا outbound فقد يكون هذا للمكالمة الواردة (بعد accept)
    if (phase == CallUiPhase.outgoingDialing ||
        phase == CallUiPhase.outgoingConnecting) {
      phase = CallUiPhase.outgoingConnecting;
    }
    final sdpAnswer = event.call!.sdpAnswer ?? currentCall?.sdpAnswer;
    if (sdpAnswer != null &&
        sdpAnswer.isNotEmpty &&
        (isOutbound || phase == CallUiPhase.outgoingConnecting)) {
      unawaited(_applyAnswerSafely(sdpAnswer));
    }
    update();
  }

  Future<void> _applyAnswerSafely(String sdp) async {
    try {
      await _webrtc?.applyAnswer(sdp);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('❌ applyAnswer error: $e');
      }
      lastError = 'failed_to_connect_audio'.tr;
      update();
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

  void _onCallAccepted(CallEvent event) {
    if (event.call != null) {
      currentCall = _mergeCall(event.call!);
    }
    _stopRingtones();
    _stopRingback();
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

  /// قبول مكالمة واردة.
  Future<void> acceptIncomingCall() async {
    final call = currentCall;
    if (call == null || isProcessing) return;
    if (phase != CallUiPhase.ringingIncoming) return;

    isProcessing = true;
    phase = CallUiPhase.outgoingConnecting; // UI: Connecting
    update();
    await _stopRingtones();
    // انتقال فوري للحوار النشط ليرى المستخدم حالة "جاري التوصيل" بدلاً من
    // حوار الرنين المعطّل.
    switchToActiveDialog();

    try {
      // SDP offer قد يكون داخل الحدث أو نحتاج جلبه
      String? sdpOffer = call.sdpOffer;
      if (sdpOffer == null || sdpOffer.isEmpty) {
        final sdpResult = await getCallSdpUseCase(call.id);
        final sdpFailure = sdpResult.fold<CallFailureInfo?>(
          (failure) => CallFailureInfo.fromFailure(
            failure,
            'failed_to_load_sdp'.tr,
          ),
          (callWithSdp) {
            sdpOffer = callWithSdp.sdpOffer;
            currentCall = _mergeCall(callWithSdp);
            return null;
          },
        );
        if (sdpFailure != null) {
          _showCallError(sdpFailure.message);
          await _finalizeCallTeardown();
          return;
        }
      }
      if (sdpOffer == null || sdpOffer!.isEmpty) {
        _showCallError('failed_to_load_sdp'.tr);
        await _finalizeCallTeardown();
        return;
      }

      await _ensureWebRtc();
      await _webrtc!.applyOffer(sdpOffer!);
      final sdpAnswer = await _webrtc!.createAnswer();

      final acceptResult = await acceptCallUseCase(
        AcceptCallParams(callId: call.id, sdpAnswer: sdpAnswer),
      );
      final acceptFailure = acceptResult.fold<CallFailureInfo?>(
        (failure) => CallFailureInfo.fromFailure(
          failure,
          'failed_to_accept_call'.tr,
        ),
        (updated) {
          currentCall = _mergeCall(updated);
          return null;
        },
      );
      if (acceptFailure != null) {
        _showCallError(acceptFailure.message);
        await _finalizeCallTeardown();
        return;
      }
      // ننتظر call_accepted من السيرفر لتعديل الحالة إلى in_progress.
      update();
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('❌ acceptIncomingCall error: $e');
      }
      _showCallError('failed_to_accept_call'.tr);
      await _finalizeCallTeardown();
    } finally {
      isProcessing = false;
      update();
    }
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
        (failure) => CallFailureInfo.fromFailure(
          failure,
          'failed_to_reject_call'.tr,
        ),
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
        (failure) async => CallFailureInfo.fromFailure(
          failure,
          'failed_to_initiate_call'.tr,
        ),
        (initiated) async {
          currentCall = _mergeCall(initiated);
          return null;
        },
      );

      if (failureInfo != null) {
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
      // اقترح إرسال طلب إذن المكالمة (template) — يستغرق Meta حتى 7 أيام
      // بعد قبول العميل.
      final confirm = await Get.dialog<bool>(
        AlertDialog(
          title: Text('call_permission_required'.tr),
          content: Text(
            'call_permission_required_body'.trParams({
              'phone': toPhone,
            }),
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
        await requestCallingPermission(
          sessionId: sessionId,
          toPhone: toPhone,
        );
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
      RequestCallPermissionParams(
        sessionId: sessionId,
        to: normalized,
      ),
    );
    result.fold(
      (failure) {
        AppMessages.showSnackBar(
          type: ErrorType.error,
          title: 'error'.tr,
          message: failure.message ??
              'failed_to_send_permission_request'.tr,
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
    result.fold(
      (_) {},
      (call) {
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
      },
    );
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
    _activeCallPollTimer = Timer.periodic(
      const Duration(seconds: 7),
      (_) => unawaited(_pollActiveCallsOnce()),
    );
  }

  Future<void> _pollActiveCallsOnce() async {
    if (_activeCallPollInFlight) return;
    if (hasActiveCall) return; // لدينا مكالمة بالفعل
    if (sessions.isEmpty) return;
    _activeCallPollInFlight = true;
    try {
      for (final session in sessions) {
        if (hasActiveCall) break;
        final result = await getActiveCallUseCase(session.id);
        result.fold(
          (_) {},
          (call) {
            if (call == null) return;
            // وجدنا مكالمة على السيرفر، لكن لا شيء محلياً.
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
          },
        );
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

  Future<void> _finalizeCallTeardown() async {
    _callTimer?.cancel();
    _callTimer = null;
    _callStartedAt = null;
    callDuration = Duration.zero;
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
    if (Platform.isWindows) return; // على ويندوز نتجنّب audioplayers خاص بنغمة الواردة
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

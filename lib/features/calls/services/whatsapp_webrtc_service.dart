import 'dart:async';

import 'package:alma_desktop/features/calls/domain/entities/ice_server.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Wrapper بسيط حول `flutter_webrtc` يُجهّز peer connection صوتي للمكالمات،
/// ويعرّض API يطابق ما يحتاجه التدفّق الموصوف في `WHATSAPP_CALLING_API.md`:
///
/// - Outbound: [start] → [createOffer] → [applyAnswer] (يُمرَّر من call_connected)
/// - Inbound:  [start] → [applyOffer] → [createAnswer]
///
/// كلا الاتجاهين يضمنان اكتمال تجميع ICE قبل إعادة الـ SDP، وذلك متوافق مع
/// متطلبات Meta التي تحتاج الـ candidates مضمّنة داخل الـ SDP.
class WhatsAppWebRtcService {
  RTCPeerConnection? _peer;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  bool _isClosed = false;
  bool _isMuted = false;
  RTCPeerConnectionState? _connectionState;
  Completer<void>? _connectedCompleter;

  /// callbacks
  void Function(RTCPeerConnectionState state)? onConnectionState;
  void Function(RTCIceConnectionState state)? onIceState;
  void Function(MediaStream stream)? onRemoteStream;

  bool get isMuted => _isMuted;
  MediaStream? get remoteStream => _remoteStream;

  /// ينشئ peer connection ويُضيف مسار صوتي محلي. يجب استدعاؤها قبل
  /// [createOffer] أو [applyOffer].
  Future<void> start({required List<IceServer> iceServers}) async {
    _isClosed = false;
    _isMuted = false;
    _connectionState = null;
    _connectedCompleter = Completer<void>();
    _connectedCompleter!.future.ignore();

    final config = <String, dynamic>{
      'iceServers': iceServers
          .map(
            (s) => <String, dynamic>{
              'urls': s.urls.length == 1 ? s.urls.first : s.urls,
              if (s.username != null) 'username': s.username,
              if (s.credential != null) 'credential': s.credential,
            },
          )
          .toList(),
      'sdpSemantics': 'unified-plan',
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
    };

    _peer = await createPeerConnection(config);

    _peer!.onConnectionState = (state) {
      _connectionState = state;
      final connected = _connectedCompleter;
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected &&
          connected != null &&
          !connected.isCompleted) {
        connected.complete();
      } else if ((state ==
                  RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
              state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) &&
          connected != null &&
          !connected.isCompleted) {
        connected.completeError(
          StateError('WebRTC audio connection failed: $state'),
        );
      }
      if (kDebugMode) {
        // ignore: avoid_print
        print('📶 Peer connection state: $state');
      }
      onConnectionState?.call(state);
    };
    _peer!.onIceConnectionState = (state) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('🧊 ICE connection state: $state');
      }
      onIceState?.call(state);
    };
    _peer!.onIceGatheringState = (state) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('🧊 ICE gathering state: $state');
      }
    };
    _peer!.onSignalingState = (state) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('🔔 Signaling state: $state');
      }
    };
    _peer!.onTrack = (RTCTrackEvent event) {
      if (kDebugMode) {
        // ignore: avoid_print
        print(
          '🔊 Remote track received: kind=${event.track.kind} '
          'enabled=${event.track.enabled} streams=${event.streams.length}',
        );
      }
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        // ضمان تشغيل تلقائي للصوت — flutter_webrtc على macOS/Windows
        // عادةً يُشغّل الصوت تلقائياً، لكن نُفعّل المسارات لضمان ذلك.
        for (final track in _remoteStream!.getAudioTracks()) {
          track.enabled = true;
        }
        onRemoteStream?.call(_remoteStream!);
      }
    };

    // الميكروفون فقط
    final mediaConstraints = <String, dynamic>{
      'audio': {
        'mandatory': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'optional': const [],
      },
      'video': false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    for (final track in _localStream!.getAudioTracks()) {
      await _peer!.addTrack(track, _localStream!);
      if (kDebugMode) {
        // ignore: avoid_print
        print(
          '🎤 Local audio track added: id=${track.id} enabled=${track.enabled}',
        );
      }
    }
  }

  /// Waits until the peer has a live audio transport. Compliance audio must
  /// not start before this point or the customer could miss the announcement.
  Future<void> waitUntilConnected({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_connectionState ==
        RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
      return;
    }
    final connected = _connectedCompleter;
    if (connected == null) {
      throw StateError('WebRTC peer not started');
    }
    await connected.future.timeout(
      timeout,
      onTimeout: () => throw TimeoutException(
        'WebRTC audio did not connect within ${timeout.inSeconds} seconds',
      ),
    );
  }

  /// ينشئ Offer ويعيد SDP بعد اكتمال تجميع ICE.
  Future<String> createOffer() async {
    final peer = _ensurePeer();
    final offer = await peer.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    });
    await peer.setLocalDescription(offer);
    final completed = await _waitForIceComplete(peer);
    final desc = completed?.sdp ?? offer.sdp ?? '';
    final normalized = normalizeSdp(desc);
    _logSdpFingerprint('createOffer (local)', normalized);
    return normalized;
  }

  /// يُطبّق SDP الـ Offer القادم من الطرف الآخر (للمكالمات الواردة).
  Future<void> applyOffer(String sdp) async {
    final peer = _ensurePeer();
    final normalized = normalizeSdp(sdp);
    _logSdpFingerprint('applyOffer (remote)', normalized);
    try {
      await peer.setRemoteDescription(
        RTCSessionDescription(normalized, 'offer'),
      );
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('❌ setRemoteDescription(offer) failed: $e');
      }
      rethrow;
    }
  }

  /// ينشئ Answer ويعيد SDP بعد اكتمال تجميع ICE (للمكالمات الواردة).
  ///
  /// لا نمرّر `offerToReceive*` constraints هنا — هي مخصّصة للـ createOffer
  /// فقط. الـ answer يعكس تلقائياً ما طلبه الـ offer البعيد، وتمرير constraints
  /// إضافية قد يسبّب عدم تطابق media descriptions في بعض إصدارات libwebrtc.
  Future<String> createAnswer() async {
    final peer = _ensurePeer();
    final answer = await peer.createAnswer(<String, dynamic>{});
    await peer.setLocalDescription(answer);
    final completed = await _waitForIceComplete(peer);
    final desc = completed?.sdp ?? answer.sdp ?? '';
    final normalized = normalizeSdp(desc);
    _logSdpFingerprint('createAnswer (local)', normalized);
    return normalized;
  }

  /// يُطبّق SDP الـ Answer القادم من الطرف الآخر (للمكالمات الصادرة).
  Future<void> applyAnswer(String sdp) async {
    final peer = _ensurePeer();
    final normalized = normalizeSdp(sdp);
    _logSdpFingerprint('applyAnswer (remote)', normalized);
    try {
      await peer.setRemoteDescription(
        RTCSessionDescription(normalized, 'answer'),
      );
      if (kDebugMode) {
        // ignore: avoid_print
        print('✅ SDP answer applied — audio path establishing');
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('❌ setRemoteDescription(answer) failed: $e');
      }
      rethrow;
    }
  }

  /// كتم/إلغاء كتم الميكروفون.
  void setMicMuted(bool muted) {
    final tracks = _localStream?.getAudioTracks() ?? const [];
    for (final t in tracks) {
      t.enabled = !muted;
    }
    _isMuted = muted;
  }

  /// إغلاق الـ peer وتنظيف الموارد.
  Future<void> dispose() async {
    if (_isClosed) return;
    _isClosed = true;
    final connected = _connectedCompleter;
    if (connected != null && !connected.isCompleted) {
      connected.completeError(StateError('WebRTC peer was disposed'));
    }
    _connectedCompleter = null;
    _connectionState = RTCPeerConnectionState.RTCPeerConnectionStateClosed;
    try {
      final tracks = _localStream?.getTracks() ?? const [];
      for (final t in tracks) {
        try {
          await t.stop();
        } catch (_) {}
      }
      await _localStream?.dispose();
    } catch (_) {}
    _localStream = null;

    try {
      await _remoteStream?.dispose();
    } catch (_) {}
    _remoteStream = null;

    try {
      await _peer?.close();
    } catch (_) {}
    try {
      await _peer?.dispose();
    } catch (_) {}
    _peer = null;
  }

  RTCPeerConnection _ensurePeer() {
    final peer = _peer;
    if (peer == null) {
      throw StateError('WebRTC peer not started — call start() first');
    }
    return peer;
  }

  /// ينتظر اكتمال تجميع الـ ICE ثم يعيد الوصف المحلي النهائي.
  Future<RTCSessionDescription?> _waitForIceComplete(
    RTCPeerConnection peer,
  ) async {
    // إذا كان الـ gathering مكتمل من البداية لن يصلنا حدث، نتحقّق بـ polling.
    final completer = Completer<void>();
    Timer? safety;
    void Function(RTCIceGatheringState)? oldCb = peer.onIceGatheringState;

    void cleanup() {
      peer.onIceGatheringState = oldCb;
      safety?.cancel();
    }

    peer.onIceGatheringState = (state) {
      oldCb?.call(state);
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete &&
          !completer.isCompleted) {
        completer.complete();
      }
    };

    // كنت قد تأخرت في إرفاق المستمع، تحقّق سريعاً من الحالة الفورية
    Future<void>.delayed(const Duration(milliseconds: 50), () async {
      try {
        final state = peer.iceGatheringState;
        if (state == RTCIceGatheringState.RTCIceGatheringStateComplete &&
            !completer.isCompleted) {
          completer.complete();
        }
      } catch (_) {}
    });

    // أمان: لا ننتظر أكثر من 5 ثوانٍ حتى وإن لم يكتمل التجميع
    safety = Timer(const Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('⚠️ ICE gathering timeout — using best-effort SDP');
        }
        completer.complete();
      }
    });

    try {
      await completer.future;
    } finally {
      cleanup();
    }

    return peer.getLocalDescription();
  }

  /// تطبيع SDP بشكل صارم متطابق مع المرجع في `public/js/whatsapp-webrtc.js`.
  ///
  /// libwebrtc صارمة جداً بشأن:
  /// - كل سطر يجب أن ينتهي بـ CRLF (`\r\n`)، ليس فقط `\n`.
  /// - لا مسافات إضافية في نهاية السطور (بعض الـ proxies تحقن NBSPs).
  /// - لا سطور فارغة في وسط الـ SDP.
  /// - يجب أن ينتهي المستند بـ CRLF نهائي.
  ///
  /// SDPs القادمة من WhatsApp Cloud Calling (التي تستهدف SIP) قد تصل بـ
  /// line endings مختلطة بعد JSON → MySQL longText → JSON. هذا يسبّب أخطاء:
  ///   "Failed to parse SessionDescription. Invalid SDP line."
  @visibleForTesting
  static String normalizeSdp(String sdp) {
    if (sdp.isEmpty) return sdp;

    // 1) توحيد كل line endings إلى \n
    String s = sdp.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // 2) قص أي مسافات/NBSPs في نهاية كل سطر
    final trailingWs = RegExp(r'[\s\u00A0]+$');
    final lines = s
        .split('\n')
        .map((l) => l.replaceAll(trailingWs, ''))
        .toList();

    // 3) حذف السطور الفارغة الوسطى (يُسمح بسطر فارغ واحد في النهاية)
    final cleaned = <String>[];
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isNotEmpty || i == lines.length - 1) {
        cleaned.add(line);
      }
    }

    // 4) إعادة الانبعاث بـ CRLF صارم + CRLF نهائي
    String result = cleaned.join('\r\n');
    if (!result.endsWith('\r\n')) {
      result = '$result\r\n';
    }
    return result;
  }

  /// تسجيل بصمة SDP مختصرة لتشخيص فشل التحليل بدون إغراق الـ console.
  void _logSdpFingerprint(String label, String sdp) {
    if (!kDebugMode) return;
    if (sdp.isEmpty) {
      // ignore: avoid_print
      print('[SDP] $label: <empty>');
      return;
    }
    final lines = sdp.split(RegExp(r'\r?\n'));
    final mLines = lines.where((l) => l.startsWith('m=')).toList();
    final hasMid = lines.any((l) => l.startsWith('a=mid:'));
    final hasBundle = lines.any((l) => l.startsWith('a=group:BUNDLE'));
    // ignore: avoid_print
    print(
      '[SDP] $label: length=${sdp.length} lines=${lines.length} '
      'crlf=${sdp.contains('\r\n')} ends_crlf=${sdp.endsWith('\r\n')} '
      'm_lines=$mLines mid=$hasMid bundle=$hasBundle '
      'first="${lines.isNotEmpty ? lines.first : ""}"',
    );
  }
}

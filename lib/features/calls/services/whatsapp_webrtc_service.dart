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

    final config = <String, dynamic>{
      'iceServers': iceServers
          .map((s) => <String, dynamic>{
                'urls': s.urls.length == 1 ? s.urls.first : s.urls,
                if (s.username != null) 'username': s.username,
                if (s.credential != null) 'credential': s.credential,
              })
          .toList(),
      'sdpSemantics': 'unified-plan',
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
    };

    _peer = await createPeerConnection(config);

    _peer!.onConnectionState = (state) {
      onConnectionState?.call(state);
    };
    _peer!.onIceConnectionState = (state) {
      onIceState?.call(state);
    };
    _peer!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
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
    }
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
    return _normalizeSdp(desc);
  }

  /// يُطبّق SDP الـ Offer القادم من الطرف الآخر (للمكالمات الواردة).
  Future<void> applyOffer(String sdp) async {
    final peer = _ensurePeer();
    final normalized = _normalizeSdp(sdp);
    await peer.setRemoteDescription(
      RTCSessionDescription(normalized, 'offer'),
    );
  }

  /// ينشئ Answer ويعيد SDP بعد اكتمال تجميع ICE (للمكالمات الواردة).
  Future<String> createAnswer() async {
    final peer = _ensurePeer();
    final answer = await peer.createAnswer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    });
    await peer.setLocalDescription(answer);
    final completed = await _waitForIceComplete(peer);
    final desc = completed?.sdp ?? answer.sdp ?? '';
    return _normalizeSdp(desc);
  }

  /// يُطبّق SDP الـ Answer القادم من الطرف الآخر (للمكالمات الصادرة).
  Future<void> applyAnswer(String sdp) async {
    final peer = _ensurePeer();
    final normalized = _normalizeSdp(sdp);
    await peer.setRemoteDescription(
      RTCSessionDescription(normalized, 'answer'),
    );
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

  /// Chrome/libwebrtc صارمتان بشأن CRLF. أي خط نقل قد يحوّلها إلى LF.
  String _normalizeSdp(String sdp) {
    if (sdp.isEmpty) return sdp;
    final unified = sdp.replaceAll('\r\n', '\n').replaceAll('\n', '\r\n').trim();
    return '$unified\r\n';
  }
}

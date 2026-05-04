import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

class ReverbService {
  final String appKey;
  final String host;
  final int port;
  final String scheme;
  final String apiBaseUrl;
  final String? authToken; // Sanctum token

  WebSocketChannel? _channel;
  String? _socketId;
  bool _isConnected = false;
  bool _isReconnecting = false;
  bool _shouldReconnect = true;

  // إعادة الاتصال
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  // Ping/Pong لإبقاء الاتصال نشطاً
  Timer? _pingTimer;
  static const Duration _pingInterval = Duration(seconds: 30);

  // تتبع القنوات المشتركة لإعادة الاشتراك بعد إعادة الاتصال
  final Set<String> _subscribedChannels = <String>{};

  ReverbService({
    required this.appKey,
    required this.host,
    required this.port,
    required this.scheme,
    required this.apiBaseUrl,
    this.authToken,
  });

  /// الاتصال بـ Reverb Server
  Future<void> connect() async {
    if (_isReconnecting) {
      return;
    }

    try {
      // بناء WebSocket URL
      final wsUrl = _buildWebSocketUrl();

      // إغلاق الاتصال السابق إن وجد
      _channel?.sink.close();

      // إنشاء WebSocket connection
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // الاستماع إلى الرسائل الواردة
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          _isConnected = false;
          _stopPingTimer();
          onConnectionError?.call(error);
          _scheduleReconnect();
        },
        onDone: () {
          _isConnected = false;
          _stopPingTimer();
          onConnectionClosed?.call();

          // إعادة الاتصال إذا كان يجب ذلك
          if (_shouldReconnect) {
            _scheduleReconnect();
          }
        },
        cancelOnError: false, // لا إلغاء عند الخطأ، نتعامل معه يدوياً
      );

      _isConnected = true;
      _reconnectAttempts = 0; // إعادة تعيين محاولات إعادة الاتصال

      // بدء ping timer
      _startPingTimer();

      onConnected?.call();

      // إعادة الاشتراك في القنوات المشتركة سابقاً
      if (_subscribedChannels.isNotEmpty) {
        await Future.delayed(
          const Duration(milliseconds: 500),
        ); // انتظار قليلاً
        for (final channel in _subscribedChannels) {
          try {
            await subscribeToPrivateChannel(channel);
          } catch (e) {
            if (kDebugMode) print('❌ Error re-subscribing to $channel: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error connecting to Reverb: $e');
      _isConnected = false;
      _stopPingTimer();
      onConnectionError?.call(e);
      _scheduleReconnect();
      rethrow;
    }
  }

  /// بناء WebSocket URL
  String _buildWebSocketUrl() {
    // دعم 'https' كمرادف لـ 'wss' للاتصال الآمن
    final isSecure = scheme == 'wss' || scheme == 'https';
    final protocol = isSecure ? 'wss' : 'ws';
    final portStr = (isSecure && port == 443) || (!isSecure && port == 80)
        ? ''
        : ':$port';
    return '$protocol://$host$portStr/app/$appKey?protocol=7&client=flutter&version=1.0.0';
  }

  /// معالجة الرسائل الواردة
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final event = data['event'] as String?;

      if (event == 'pusher:connection_established') {
        final socketData = jsonDecode(data['data'] as String);
        _socketId = socketData['socket_id'] as String?;
        if (kDebugMode) print('✅ Socket ID: $_socketId');
        _isReconnecting = false; // إعادة الاتصال نجحت
        onSocketIdReceived?.call(_socketId!);
      } else if (event == 'pusher:pong') {
        // استجابة ping - الاتصال لا يزال نشطاً
        if (kDebugMode) print('🏓 Pong received');
      } else if (event == 'pusher:error') {
        final errorData = jsonDecode(data['data'] as String);
        if (kDebugMode) print('❌ Pusher error: $errorData');
        onError?.call(errorData);
      } else if (event == 'pusher:subscription_succeeded') {
        final channelName = data['channel'] as String?;
        if (kDebugMode) print('✅ Subscribed successfully to: $channelName');
        onSubscriptionSucceeded?.call(channelName ?? '');
      } else if (event?.startsWith('pusher:') == false) {
        // هذا حدث مخصص (مثل message.received)
        final channelName = data['channel'] as String?;
        final eventData = data['data'];
        _handleCustomEvent(event!, eventData, channelName);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error handling message: $e');
      if (kDebugMode) print('Message: $message');
    }
  }

  /// معالجة الأحداث المخصصة
  void _handleCustomEvent(String event, dynamic data, String? channelName) {
    if (kDebugMode) print('📨 Event received: $event on channel: $channelName');

    try {
      // البيانات قد تكون String أو Map
      Map<String, dynamic> eventData;
      if (data is String) {
        eventData = jsonDecode(data) as Map<String, dynamic>;
      } else if (data is Map) {
        eventData = data as Map<String, dynamic>;
      } else {
        if (kDebugMode) print('❌ Unknown data type: ${data.runtimeType}');
        return;
      }

      if (event == 'message.received') {
        onMessageReceived?.call(eventData);
      } else if (event == 'deal.history.updated') {
        onDealHistoryUpdated?.call(eventData);
      } else {
        // حدث غير معروف
        onUnknownEvent?.call(event, eventData);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error parsing event data: $e');
      if (kDebugMode) print('Data: $data');
    }
  }

  /// الاشتراك في قناة خاصة (Private Channel)
  Future<void> subscribeToPrivateChannel(String channelName) async {
    if (!_isConnected || _socketId == null) {
      throw Exception('Not connected to Reverb. Socket ID: $_socketId');
    }

    try {
      // 1. طلب التخويل من Laravel
      final authData = await _authorizeChannel(channelName, _socketId!);

      // 2. إرسال طلب الاشتراك
      final subscribeMessage = jsonEncode({
        'event': 'pusher:subscribe',
        'data': {
          'channel': channelName,
          'auth': authData['auth'],
          'channel_data': authData['channel_data'],
        },
      });

      _channel?.sink.add(subscribeMessage);
      _subscribedChannels.add(channelName); // تتبع القناة المشتركة
      if (kDebugMode) print('✅ Subscribed to channel: $channelName');
    } catch (e) {
      if (kDebugMode) print('❌ Error subscribing to channel: $e');
      rethrow;
    }
  }

  /// طلب التخويل للقناة من Laravel
  Future<Map<String, dynamic>> _authorizeChannel(
    String channelName,
    String socketId,
  ) async {
    if (authToken == null) {
      throw Exception('Auth token is required for private channels');
    }

    // ملاحظة: Laravel يسجل /broadcasting/auth تلقائياً ويدعم Sanctum
    // استخدم URL الكامل (بدون /api) لأن Laravel يسجله في web routes
    // إزالة /api/ من نهاية URL
    String baseUrl = apiBaseUrl;
    if (baseUrl.endsWith('/api/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 5); // إزالة '/api/'
    } else if (baseUrl.endsWith('/api')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 4); // إزالة '/api'
    }

    // التأكد من أن baseUrl ينتهي بـ /
    if (!baseUrl.endsWith('/')) {
      baseUrl = '$baseUrl/';
    }

    final url = Uri.parse('${baseUrl}broadcasting/auth');

    if (kDebugMode) print('🔐 Authorizing channel: $channelName');
    if (kDebugMode) print('🔐 URL: $url');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'socket_id': socketId, 'channel_name': channelName}),
    );

    if (response.statusCode == 200) {
      final authData = jsonDecode(response.body) as Map<String, dynamic>;
      if (kDebugMode) print('✅ Channel authorized successfully');
      return authData;
    } else {
      throw Exception(
        'Authorization failed: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// الاشتراك في قناة رسائل الصفقة
  Future<void> subscribeToDealMessages(int dealId) async {
    final channelName = 'private-deal.$dealId';
    await subscribeToPrivateChannel(channelName);
  }

  /// الاشتراك في قناة الوكيل (رسائل جديدة من أي صفقة — للقائمة العامة)
  Future<void> subscribeToCrmAgent(int userId) async {
    final channelName = 'private-crm.agent.$userId';
    await subscribeToPrivateChannel(channelName);
  }

  /// الاشتراك في قناة التصور (للأدمن — رسائل جديدة من أي صفقة)
  Future<void> subscribeToCrmVisualization() async {
    const channelName = 'private-crm.visualization';
    await subscribeToPrivateChannel(channelName);
  }

  /// إلغاء الاشتراك من قناة
  void unsubscribeFromChannel(String channelName) {
    final unsubscribeMessage = jsonEncode({
      'event': 'pusher:unsubscribe',
      'data': {'channel': channelName},
    });

    _channel?.sink.add(unsubscribeMessage);
    _subscribedChannels.remove(channelName); // إزالة من القائمة
    if (kDebugMode) print('🔌 Unsubscribed from channel: $channelName');
  }

  /// إغلاق الاتصال
  void disconnect() {
    _shouldReconnect = false; // منع إعادة الاتصال
    _stopPingTimer();
    _stopReconnectTimer();
    _channel?.sink.close();
    _channel = null;
    _socketId = null;
    _isConnected = false;
    _subscribedChannels.clear();
    if (kDebugMode) print('🔌 Disconnected from Reverb');
  }

  /// جدولة إعادة الاتصال
  void _scheduleReconnect() {
    if (!_shouldReconnect || _isReconnecting) {
      return;
    }

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      if (kDebugMode) {
        print('❌ Max reconnect attempts reached. Stopping reconnection.');
      }
      _shouldReconnect = false;
      return;
    }

    _reconnectAttempts++;
    _isReconnecting = true;

    final delay = Duration(
      milliseconds: _reconnectDelay.inMilliseconds * _reconnectAttempts,
    );

    if (kDebugMode) {
      print(
        '🔄 Scheduling reconnect attempt $_reconnectAttempts/$_maxReconnectAttempts in ${delay.inSeconds}s...',
      );
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      if (kDebugMode) print('🔄 Reconnecting... (attempt $_reconnectAttempts)');
      try {
        await connect();
      } catch (e) {
        if (kDebugMode) print('❌ Reconnection failed: $e');
        _isReconnecting = false;
        _scheduleReconnect(); // محاولة مرة أخرى
      }
    });
  }

  /// بدء ping timer لإبقاء الاتصال نشطاً
  void _startPingTimer() {
    _stopPingTimer();
    _pingTimer = Timer.periodic(_pingInterval, (timer) {
      if (_isConnected && _channel != null) {
        try {
          final pingMessage = jsonEncode({'event': 'pusher:ping', 'data': {}});
          _channel?.sink.add(pingMessage);
          if (kDebugMode) print('🏓 Ping sent');
        } catch (e) {
          if (kDebugMode) print('❌ Error sending ping: $e');
          _stopPingTimer();
        }
      } else {
        _stopPingTimer();
      }
    });
  }

  /// إيقاف ping timer
  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  /// إيقاف reconnect timer
  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// Callbacks للأحداث
  Function()? onConnected;
  Function(dynamic)? onConnectionError;
  Function()? onConnectionClosed;
  Function(String)? onSocketIdReceived;
  Function(Map<String, dynamic>)? onMessageReceived;
  Function(Map<String, dynamic>)? onDealHistoryUpdated;
  Function(String, Map<String, dynamic>)? onUnknownEvent;
  Function(Map<String, dynamic>)? onError;
  Function(String)? onSubscriptionSucceeded;

  bool get isConnected => _isConnected;
  String? get socketId => _socketId;
}

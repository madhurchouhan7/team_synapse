// lib/core/network/ws_client.dart
// ─────────────────────────────────────────────────────────────────────────────
// Singleton WebSocket client for real-time smart plug telemetry.
//
// Usage:
//   WsClient.instance.connect(userId: uid);
//   WsClient.instance.stream.listen((event) { ... });
//   WsClient.instance.disconnect();
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_constants.dart';

/// Typed WebSocket event
class WsEvent {
  final String type;
  final Map<String, dynamic> data;
  final DateTime receivedAt;

  const WsEvent({
    required this.type,
    required this.data,
    required this.receivedAt,
  });

  factory WsEvent.fromJson(Map<String, dynamic> json) {
    return WsEvent(
      type:       json['type'] as String? ?? 'unknown',
      data:       (json['data'] as Map?)?.cast<String, dynamic>() ?? {},
      receivedAt: DateTime.now(),
    );
  }
}

class WsClient {
  WsClient._();
  static final WsClient instance = WsClient._();

  WebSocketChannel? _channel;
  StreamController<WsEvent>? _controller;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  String? _userId;
  bool _intentionalDisconnect = false;
  int _reconnectAttempts = 0;

  static const int _maxReconnectAttempts = 10;
  static const Duration _pingInterval = Duration(seconds: 20);

  /// Public stream of typed WS events
  Stream<WsEvent> get stream =>
      _controller?.stream ?? const Stream.empty();

  bool get isConnected => _channel != null;

  /// Connect to the server WebSocket with optional userId for subscription
  Future<void> connect({required String userId}) async {
    if (_channel != null) return; // already connected

    _userId                  = userId;
    _intentionalDisconnect   = false;

    _controller ??= StreamController<WsEvent>.broadcast();

    final wsUrl = _buildWsUrl(userId);
    _doConnect(wsUrl);
  }

  void _doConnect(Uri wsUrl) {
    try {
      _channel = WebSocketChannel.connect(wsUrl);

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone:  _onDone,
        cancelOnError: false,
      );

      _startPing();
      _reconnectAttempts = 0;

    } catch (e) {
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final event = WsEvent.fromJson(json);

      // Handle server-side ping by sending pong back
      if (event.type == 'ping') {
        _send({'type': 'pong'});
        return;
      }

      _controller?.add(event);
    } catch (_) {}
  }

  void _onError(Object error) {
    _cleanupChannel();
    _scheduleReconnect();
  }

  void _onDone() {
    _cleanupChannel();
    if (!_intentionalDisconnect) {
      _scheduleReconnect();
    }
  }

  void _cleanupChannel() {
    _pingTimer?.cancel();
    _channel = null;
  }

  void _scheduleReconnect() {
    if (_intentionalDisconnect) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) return;

    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2); // exponential backoff

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_userId != null && !_intentionalDisconnect) {
        _doConnect(_buildWsUrl(_userId!));
      }
    });
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      _send({'type': 'ping'});
    });
  }

  void _send(Map<String, dynamic> payload) {
    if (_channel != null) {
      try {
        _channel!.sink.add(jsonEncode(payload));
      } catch (_) {}
    }
  }

  /// Gracefully disconnect
  void disconnect() {
    _intentionalDisconnect = true;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  /// Dispose (call on app shutdown)
  Future<void> dispose() async {
    disconnect();
    await _controller?.close();
    _controller = null;
  }

  Uri _buildWsUrl(String userId) {
    final base = ApiConstants.baseUrl;
    // Convert http(s):// → ws(s)://
    final wsBase = base
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    // Remove /api and trailing slashes
    final host = wsBase.replaceAll(RegExp(r'/api.*$'), '');
    return Uri.parse('$host/ws?userId=$userId');
  }
}

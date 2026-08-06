import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../network/api_endpoints.dart';

/// Cliente WebSocket con reconexión automática.
/// Se conecta al namespace /realtime del backend y se
/// une a la sala de la pareja para recibir el evento "match:new" en directo.
class SocketService {
  io.Socket? _socket;
  String? _token;
  String? _coupleId;
  void Function(Map<String, dynamic>)? _onMatch;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _manuallyDisconnected = false;

  void connect({
    required String token,
    required String coupleId,
    required void Function(Map<String, dynamic> match) onMatch,
  }) {
    _token = token;
    _coupleId = coupleId;
    _onMatch = onMatch;
    _manuallyDisconnected = false;
    _reconnectAttempts = 0;
    _doConnect();
  }

  void _doConnect() {
    _socket = io.io(
      '${ApiEndpoints.socketUrl}/realtime',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!
      ..onConnect((_) {
        _reconnectAttempts = 0;
        _socket!.emit('join', {'token': _token, 'coupleId': _coupleId});
      })
      ..on('match:new', (data) {
        if (_onMatch != null) {
          _onMatch!(Map<String, dynamic>.from(data));
        }
      })
      ..onDisconnect((_) {
        if (!_manuallyDisconnected) {
          _scheduleReconnect();
        }
      })
      ..onError((_) {
        if (!_manuallyDisconnected) {
          _scheduleReconnect();
        }
      })
      ..connect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_reconnectAttempts >= 10) return;

    final delay = Duration(seconds: 1 << _reconnectAttempts); // 1s, 2s, 4s, 8s, ...
    _reconnectAttempts++;

    _reconnectTimer = Timer(delay, () {
      if (_token != null && _coupleId != null && !_manuallyDisconnected) {
        _doConnect();
      }
    });
  }

  void disconnect() {
    _manuallyDisconnected = true;
    _reconnectTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _token = null;
    _coupleId = null;
    _onMatch = null;
  }
}

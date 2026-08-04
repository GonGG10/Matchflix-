import 'package:socket_io_client/socket_io_client.dart' as io;
import '../network/api_endpoints.dart';

/// Cliente WebSocket. Se conecta al namespace /realtime del backend y se
/// une a la sala de la pareja para recibir el evento "match:new" en directo.
class SocketService {
  io.Socket? _socket;

  void connect({required String token, required String coupleId, required void Function(Map<String, dynamic> match) onMatch}) {
    _socket = io.io(
      '${ApiEndpoints.socketUrl}/realtime',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!
      ..onConnect((_) => _socket!.emit('join', {'token': token, 'coupleId': coupleId}))
      ..on('match:new', (data) => onMatch(Map<String, dynamic>.from(data)))
      ..connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}

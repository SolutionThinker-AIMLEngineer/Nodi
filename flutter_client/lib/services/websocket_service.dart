import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  bool get isConnected => _channel != null;

  Future<void> connect(String serverUrl, int clientId) async {
    final uri = Uri.parse('$serverUrl/ws/$clientId');
    _channel = WebSocketChannel.connect(uri);
    await _channel!.ready;

    _channel!.stream.listen(
      (raw) {
        final data = jsonDecode(raw as String);
        _messageController.add(data);
      },
      onError: (error) {
        _messageController
            .add({'status': 'error', 'message': error.toString()});
      },
      onDone: () {
        _messageController
            .add({'status': 'disconnected', 'message': 'Connection closed'});
      },
    );
  }

  void sendMessage(int fromId, int toId, String message) {
    if (_channel == null) return;
    final payload = jsonEncode({
      'from': fromId,
      'to': toId,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    });
    _channel!.sink.add(payload);
  }

  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    _messageController.close();
    _channel?.sink.close();
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

String base = "med-history-agent.decrackle.io";

class CabinStreamMessage {
  final String type;
  final Map<String, dynamic> data;

  CabinStreamMessage({required this.type, required this.data});

  factory CabinStreamMessage.fromJson(Map<String, dynamic> json) {
    return CabinStreamMessage(
      type: (json['type'] ?? '').toString(),
      data: json,
    );
  }

  @override
  String toString() => 'CabinStreamMessage(type: $type, data: $data)';
}

class CabinStreamConnection {
  final WebSocketChannel _channel;
  final Stream<CabinStreamMessage> messages;

  CabinStreamConnection._(this._channel, this.messages);

  factory CabinStreamConnection.connect({
    required String sessionId,
    required String accessToken,
    bool secure = true,
  }) {
    final scheme = secure ? "wss" : "ws";
    final uri = Uri.parse(
      "$scheme://$base/api/v1/cabin/$sessionId/stream?token=$accessToken",
    );
    print("🔌 [CabinStream] Connecting to: $uri");
    final channel = WebSocketChannel.connect(uri);

    final messages = channel.stream.map((event) {
      if (event is String) {
        print("📨 [CabinStream] JSON message: $event");
        return CabinStreamMessage.fromJson(jsonDecode(event));
      } else {
        // Binary messages are not expected from server in this protocol, 
        // but we handle them if they arrive as raw data.
        print("📨 [CabinStream] Binary message received");
        return CabinStreamMessage(type: 'binary', data: {'bytes': event});
      }
    });

    return CabinStreamConnection._(channel, messages);
  }

  void start({String mimeType = "audio/l16;rate=16000", Map<String, dynamic>? extra}) {
    final message = jsonEncode({
      "type": "start",
      "mime_type": mimeType,
      ...?extra,
    });
    _channel.sink.add(message);
  }

  void sendAudioChunk(List<int> bytes) {
    _channel.sink.add(bytes);
  }

  void sendNote(String text) {
    final message = jsonEncode({
      "type": "note",
      "text": text,
    });
    _channel.sink.add(message);
  }

  void ping() {
    _channel.sink.add(jsonEncode({"type": "ping"}));
  }

  void stop() {
    _channel.sink.add(jsonEncode({"type": "stop"}));
  }

  Future<void> close() {
    return _channel.sink.close();
  }
}

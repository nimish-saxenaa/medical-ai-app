import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

/// A single parsed Server-Sent-Event: `event: <name>` + `data: <json/text>`.
String baseUrl = "https://med-history-agent.decrackle.io";
String base = "med-history-agent.decrackle.io";

class SseEvent {
  final String event;
  final dynamic data; // decoded JSON if possible, otherwise raw string

  SseEvent({required this.event, required this.data});

  @override
  String toString() => 'SseEvent(event: $event, data: $data)';
}

/// POST /api/v1/consultation/{session_id}/answer-stream
/// text/event-stream response.
/// Events: 'token' {text}, 'error' {message},
///         'done' {next_question, history_complete, new_flags}.
Stream<SseEvent> submitAnswerStream({
  required String token,
  required String sessionId,
  required String answer,
}) async* {
  final uri = Uri.parse(
    "$baseUrl/api/v1/consultation/$sessionId/answer-stream",
  );

  final request = http.Request("POST", uri)
    ..headers["Content-Type"] = "application/json"
    ..headers["Authorization"] = "Bearer $token"
    ..body = jsonEncode({"answer": answer});

  final response = await http.Client().send(request);

  await for (final line
      in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
    // Ignore empty lines
    if (line.isEmpty) continue;

    // We only care about lines beginning with "data:"
    if (!line.startsWith("data:")) continue;

    final jsonString = line.substring(5).trim();

    final Map<String, dynamic> json = jsonDecode(jsonString);

    yield SseEvent(event: json["event"], data: json);
  }
}

/// GET /api/v1/consultation/{session_id}/pipeline?token=...
/// Auth via query param (EventSource can't set headers), not the Bearer header.
/// Sequential 'step' events (translate, completeness, summarize, diagnose)
/// with status running|done, then a final 'complete' event {note, diagnosis}
/// or 'error'.
Stream<SseEvent> consultationPipeline({
  required String sessionId,
  required String accessToken,
}) async* {
  final uri = Uri.parse(
    "$baseUrl/api/v1/consultation/$sessionId/pipeline?token=$accessToken",
  );

  final request = http.Request("GET", uri);
  final response = await http.Client().send(request);

  final buffer = StringBuffer();

  await for (final line
      in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
    // Ignore keepalive comments
    if (line.startsWith(":")) continue;

    if (line.startsWith("data:")) {
      buffer.write(line.substring(5).trim());
    }

    // Empty line = end of one SSE event
    if (line.isEmpty) {
      if (buffer.isEmpty) continue;

      final raw = buffer.toString();

      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;

        yield SseEvent(event: json["event"] as String, data: json);
      } catch (_) {
        // Ignore malformed events
      }

      buffer.clear();
    }
  }
}

/// A single message received over the voice-stream WebSocket.
class VoiceStreamMessage {
  final String type; // ready, ack, processing, transcript, token, done, error
  final Map<String, dynamic> data;

  VoiceStreamMessage({required this.type, required this.data});

  factory VoiceStreamMessage.fromJson(Map<String, dynamic> json) {
    return VoiceStreamMessage(
      type: (json['type'] ?? '').toString(),
      data: json,
    );
  }

  @override
  String toString() => 'VoiceStreamMessage(type: $type, data: $data)';
}

/// WS /api/v1/consultation/{session_id}/voice-stream?token=...
/// Wraps the raw WebSocketChannel with helpers matching the documented protocol:
///
/// Backend Protocol (Client-Initiated):
///   1. Connect to WebSocket
///   2. Client sends: {"type": "start", "mime_type": "audio/aac"}
///   3. Server responds: {"type": "ready"}
///   4. Client streams binary audio chunks
///   5. Client sends: {"type": "stop"}
///   6. Server sends: transcript, streamed tokens, then done
///
/// Listen to `messages` for parsed server events.
class VoiceStreamConnection {
  final WebSocketChannel _channel;
  final Stream<VoiceStreamMessage> messages;

  VoiceStreamConnection._(this._channel, this.messages);

  factory VoiceStreamConnection.connect({
    // host only, no scheme, e.g. "example.com" or "example.com:443"
    required String sessionId,
    required String accessToken,
    bool secure = true,
  }) {
    final scheme = secure ? "wss" : "ws";
    final uri = Uri.parse(
      "$scheme://$base/api/v1/consultation/$sessionId/voice-stream?token=$accessToken",
    );
    final channel = WebSocketChannel.connect(uri);

    final messages = channel.stream
        .where((event) => event is String) // JSON text frames only
        .map((event) {
          return VoiceStreamMessage.fromJson(
            jsonDecode(event as String) as Map<String, dynamic>,
          );
        });

    return VoiceStreamConnection._(channel, messages);
  }

  /// Send start message to initiate audio streaming.
  /// Must be called FIRST after WebSocket connection, BEFORE any audio chunks.
  /// Server will respond with {"type":"ready"} when it's ready to receive audio.
  ///
  /// Supported MIME types (backend):
  /// - audio/aac (AAC-LC) - Recommended for iOS & Android
  /// - audio/wav (PCM16) - Larger size, lossless
  /// - audio/webm;codecs=opus - Not supported in Flutter streaming
  /// - audio/ogg;codecs=opus - Not supported in Flutter streaming
  /// - audio/mp4 - Possible with AAC encoder
  void start({String mimeType = "audio/aac"}) {
    final message = jsonEncode({"type": "start", "mime_type": mimeType});
    _channel.sink.add(message);
  }

  /// Send a chunk of raw binary audio data.
  void sendAudioChunk(List<int> bytes) {
    _channel.sink.add(bytes);
  }

  /// Signals the server that audio is finished; alternatively just close().
  void stopRecording() {
    final message = jsonEncode({"type": "stop"});
    _channel.sink.add(message);
  }

  Future<void> close() {
    return _channel.sink.close();
  }
}

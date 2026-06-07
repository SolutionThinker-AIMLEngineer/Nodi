enum MessageType { sent, received, system }

class ChatMessage {
  final String text;
  final MessageType type;
  final DateTime timestamp;
  final int? fromId;

  ChatMessage({
    required this.text,
    required this.type,
    required this.timestamp,
    this.fromId,
  });
}

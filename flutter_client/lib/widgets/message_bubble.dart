import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.system) {
      return _buildSystemMessage();
    }

    final isSent = message.type == MessageType.sent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent) ...[
            _buildAvatar(message.fromId),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isSent && message.fromId != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 3),
                    child: Text(
                      'Client #${message.fromId}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF00F5C4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSent
                        ? const Color(0xFF00F5C4).withOpacity(0.15)
                        : const Color(0xFF1A1A28),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isSent ? 16 : 4),
                      bottomRight: Radius.circular(isSent ? 4 : 16),
                    ),
                    border: Border.all(
                      color: isSent
                          ? const Color(0xFF00F5C4).withOpacity(0.2)
                          : Colors.white.withOpacity(0.05),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color:
                          isSent ? Colors.white : Colors.white.withOpacity(0.9),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
          if (isSent) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildAvatar(int? clientId) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            _colorForId(clientId),
            _colorForId(clientId).withOpacity(0.6),
          ],
        ),
      ),
      child: Center(
        child: Text(
          '${clientId ?? '?'}',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Color _colorForId(int? id) {
    final colors = [
      const Color(0xFF00F5C4),
      const Color(0xFF7C3AED),
      const Color(0xFFFF6B6B),
      const Color(0xFFFFD93D),
      const Color(0xFF6BCB77),
    ];
    return colors[(id ?? 0) % colors.length];
  }

  Widget _buildSystemMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }
}

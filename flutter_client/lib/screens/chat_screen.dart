import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/websocket_service.dart';
import '../widgets/message_bubble.dart';
import 'connect_screen.dart';

class ChatScreen extends StatefulWidget {
  final WebSocketService service;
  final int clientId;
  final String serverUrl;

  const ChatScreen({
    super.key,
    required this.service,
    required this.clientId,
    required this.serverUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _targetIdController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  List<int> _onlineClients = [];
  int? _selectedTarget;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _listenToMessages();
  }

  void _listenToMessages() {
    widget.service.messages.listen((data) {
      final status = data['status'];

      setState(() {
        switch (status) {
          case 'connected':
            _onlineClients = List<int>.from(data['online_clients'] ?? [])
              ..remove(widget.clientId);
            _addSystemMessage('Connected as Client #${widget.clientId}');
            break;

          case 'message':
            final fromId = data['from'];
            final text = data['message'] ?? '';
            _messages.add(ChatMessage(
              text: text,
              type: MessageType.received,
              timestamp: DateTime.now(),
              fromId: fromId,
            ));
            break;

          case 'delivered':
            // already shown as sent bubble, no extra needed
            break;

          case 'failed':
            _addSystemMessage('Message failed: ${data['message']}');
            break;

          case 'user_joined':
            final cid = data['client_id'];
            _onlineClients = List<int>.from(data['online_clients'] ?? [])
              ..remove(widget.clientId);
            _addSystemMessage('Client #$cid joined');
            break;

          case 'user_left':
            final cid = data['client_id'];
            _onlineClients = List<int>.from(data['online_clients'] ?? [])
              ..remove(widget.clientId);
            if (_selectedTarget == cid) {
              _selectedTarget = null;
            }
            _addSystemMessage('Client #$cid left');
            break;

          case 'disconnected':
            _isConnected = false;
            _addSystemMessage('Disconnected from server');
            break;

          case 'error':
            _addSystemMessage('Error: ${data['message']}');
            break;
        }
      });

      _scrollToBottom();
    });
  }

  void _addSystemMessage(String text) {
    _messages.add(ChatMessage(
      text: text,
      type: MessageType.system,
      timestamp: DateTime.now(),
    ));
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Determine target
    int? targetId = _selectedTarget;
    final manualTarget = int.tryParse(_targetIdController.text.trim());
    if (manualTarget != null) targetId = manualTarget;

    if (targetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a target client first'),
          backgroundColor: Color(0xFF7C3AED),
        ),
      );
      return;
    }

    widget.service.sendMessage(widget.clientId, targetId, text);

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        type: MessageType.sent,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _disconnect() async {
    await widget.service.disconnect();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ConnectScreen()),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _targetIdController.dispose();
    _scrollController.dispose();
    widget.service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Online clients strip
          if (_onlineClients.isNotEmpty) _buildOnlineStrip(),

          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => MessageBubble(message: _messages[i]),
                  ),
          ),

          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0D0D14),
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Color(0xFF00F5C4), Color(0xFF7C3AED)],
              ),
            ),
            child:
                const Icon(Icons.bolt_rounded, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'NexChat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                'You are Client #${widget.clientId}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Connection status dot
        Center(
          child: Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isConnected ? const Color(0xFF00F5C4) : Colors.redAccent,
              boxShadow: [
                BoxShadow(
                  color: (_isConnected
                          ? const Color(0xFF00F5C4)
                          : Colors.redAccent)
                      .withOpacity(0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded,
              color: Colors.redAccent, size: 20),
          onPressed: _disconnect,
          tooltip: 'Disconnect',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.white.withOpacity(0.05),
        ),
      ),
    );
  }

  Widget _buildOnlineStrip() {
    return Container(
      height: 56,
      color: const Color(0xFF0D0D14),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _onlineClients.length,
        itemBuilder: (_, i) {
          final cid = _onlineClients[i];
          final isSelected = _selectedTarget == cid;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTarget = isSelected ? null : cid;
                if (!isSelected) _targetIdController.clear();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isSelected
                    ? const Color(0xFF00F5C4).withOpacity(0.15)
                    : const Color(0xFF1A1A25),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00F5C4)
                      : Colors.white.withOpacity(0.07),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF00F5C4),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '#$cid',
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF00F5C4)
                          : Colors.white.withOpacity(0.7),
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 48, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select a client above and start chatting',
            style: TextStyle(
              color: Colors.white.withOpacity(0.12),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D14),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Column(
        children: [
          // Target override row
          if (_selectedTarget == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: _targetIdController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Type target client ID manually...',
                  hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.2), fontSize: 13),
                  prefixIcon: Icon(Icons.person_outline,
                      color: Colors.white.withOpacity(0.3), size: 18),
                  filled: true,
                  fillColor: const Color(0xFF13131A),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),

          // Recipient indicator
          if (_selectedTarget != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.arrow_forward_rounded,
                      size: 12,
                      color: const Color(0xFF00F5C4).withOpacity(0.7)),
                  const SizedBox(width: 4),
                  Text(
                    'Sending to Client #$_selectedTarget',
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFF00F5C4).withOpacity(0.7),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _selectedTarget = null),
                    child: Text(
                      'Change',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Message input + send
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                    filled: true,
                    fillColor: const Color(0xFF13131A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: Color(0xFF00F5C4), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00F5C4), Color(0xFF00C4A0)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F5C4).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.black, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

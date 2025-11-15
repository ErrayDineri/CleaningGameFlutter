import 'package:flutter/material.dart';

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [
    Message(
      text: 'مرحباً! 👋 أنا مساعدك الذكي، كيف يمكنني مساعدتك اليوم؟',
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    final userMessage = _messageController.text.trim();
    setState(() {
      _messages.add(
        Message(
          text: userMessage,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate API call with loading state
    _simulateChatbotResponse(userMessage);
  }

  void _simulateChatbotResponse(String userMessage) {
    setState(() {
      _isLoading = true;
    });

    // TODO: Replace this with actual API call later
    Future.delayed(const Duration(seconds: 1, milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _messages.add(
            Message(
              text: 'شكراً على سؤالك! ✨ سيتم إضافة الرد من خلال API قريباً.',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF0F8F5),
              const Color(0xFFE8F5F1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      const Color(0xFF1E8449),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'المساعد الذكي',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'متصل 🟢',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.support_agent,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Messages List
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Text(
                          'ابدأ المحادثة',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: Colors.grey[400],
                              ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        itemCount:
                            _messages.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length && _isLoading) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary
                                          .withOpacity(0.15),
                                      borderRadius:
                                          BorderRadius.circular(16),
                                      border: Border.all(
                                        color: colorScheme.primary
                                            .withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<
                                                    Color>(
                                              colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'جاري الكتابة...',
                                          style: TextStyle(
                                            color:
                                                colorScheme.primary,
                                            fontSize: 13,
                                            fontWeight:
                                                FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final message = _messages[index];
                          return _buildMessageBubble(context, message);
                        },
                      ),
              ),

              // Divider
              Divider(
                height: 1,
                color: Colors.grey[300],
              ),

              // Input Field
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                ),
                child: Row(
                  children: [
                    // Send Button
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            const Color(0xFF1E8449),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: _isLoading ? null : _sendMessage,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Text Field
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: !_isLoading,
                        textAlign: TextAlign.right,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'اكتب رسالتك هنا...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                        onSubmitted: _isLoading ? null : (_) => _sendMessage(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, Message message) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withOpacity(0.3),
                    colorScheme.primary.withOpacity(0.15),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.support_agent,
                size: 18,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: message.isUser
                    ? colorScheme.primary
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: message.isUser
                        ? colorScheme.primary.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: message.isUser
                    ? null
                    : Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
              ),
              child: Column(
                crossAxisAlignment: message.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    textAlign:
                        message.isUser ? TextAlign.right : TextAlign.left,
                    style: TextStyle(
                      color: message.isUser
                          ? Colors.white
                          : Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: message.isUser
                          ? Colors.white70
                          : Colors.grey[500],
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withOpacity(0.3),
                    colorScheme.primary.withOpacity(0.15),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.person_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

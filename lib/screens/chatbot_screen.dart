import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/chat_api_service.dart';

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isStreaming;

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isStreaming = false,
  });

  // Convert to JSON for persistence
  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
      };

  // Create from JSON
  factory Message.fromJson(Map<String, dynamic> json) => Message(
        text: json['text'],
        isUser: json['isUser'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  bool _isLoading = false;
  late final ScrollController _scrollController;
  String _streamingText = '';
  
  // System context for the chatbot
  static const String systemContext = '''أنت مساعد ذكي ومفيد في تطبيق "لعبة التنظيف". 
هدفك مساعدة المستخدمين في فهم اللعبة والإجابة على أسئلتهم.

معلومات عن اللعبة:
- لعبة "نظّف الحديقة": لعبة تعليمية لفرز القمامة حيث يجب وضع كل نوع في السلة المناسبة
- أنواع القمامة: بلاستيك (أزرق)، ورق (أخضر)، معدن (رمادي)
- 5 مستويات مع زيادة تدريجية في الصعوبة
- 60 ثانية لكل مستوى
- كل قطعة صحيحة = 10 نقاط
- خطأ في الوضع = -5 ثواني من الوقت
- يتم حفظ أفضل وقت لإنهاء جميع المستويات

كن لطيفاً ومفيداً وأجب بالعربية.''';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadChatHistory();
  }

  // Load chat history from SharedPreferences
  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('chat_history');
    
    if (historyJson != null && historyJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(historyJson);
        setState(() {
          _messages.clear();
          _messages.addAll(decoded.map((json) => Message.fromJson(json)).toList());
        });
      } catch (e) {
        print('Error loading chat history: $e');
        _addWelcomeMessage();
      }
    } else {
      _addWelcomeMessage();
    }
    
    // Scroll to bottom after loading
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  // Save chat history to SharedPreferences
  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = jsonEncode(
      _messages.where((m) => !m.isStreaming).map((m) => m.toJson()).toList(),
    );
    await prefs.setString('chat_history', historyJson);
  }

  // Clear chat history
  Future<void> _clearChatHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'مسح المحادثة',
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        content: const Text(
          'هل أنت متأكد من حذف جميع الرسائل؟ سيتم مسح ذاكرة المحادثة بالكامل.',
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text(
              'مسح',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Clear from storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chat_history');
      
      // Clear from memory (this wipes the conversation context)
      setState(() {
        _messages.clear();
        _streamingText = '';
        _isLoading = false;
      });
      
      // Start fresh with welcome message
      _addWelcomeMessage();
      
      // Show confirmation snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'تم مسح المحادثة بنجاح ✓',
              textAlign: TextAlign.right,
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: const Color(0xFF27AE60),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Add welcome message
  void _addWelcomeMessage() {
    setState(() {
      _messages.add(
        Message(
          text: 'مرحباً! 👋\n\nأنا هنا لمساعدتك في تعلم كيفية الحفاظ على البيئة وإعادة التدوير بشكل صحيح.\n\nكيف يمكنني مساعدتك اليوم؟',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
    _saveChatHistory();
  }

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

    // Save after adding user message
    _saveChatHistory();

    // Call streaming API
    _streamChatbotResponse(userMessage);
  }

  void _streamChatbotResponse(String userMessage) async {
    setState(() {
      _isLoading = true;
      _streamingText = '';
    });

    // Add a placeholder message for streaming
    final streamingMessageIndex = _messages.length;
    _messages.add(
      Message(
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
        isStreaming: true,
      ),
    );

    try {
      // Build conversation history with context
      final conversationHistory = <Map<String, String>>[
        {'role': 'system', 'content': systemContext},
        // Include last few messages for context (max 10)
        ..._messages
            .where((m) => !m.isStreaming)
            .skip(_messages.length > 11 ? _messages.length - 11 : 0)
            .map((m) => {
                  'role': m.isUser ? 'user' : 'assistant',
                  'content': m.text,
                }),
      ];

      print('Sending request to API...');
      print('Message count: ${conversationHistory.length}');

      // Stream the response
      var hasReceivedData = false;
      await for (var chunk in ChatApiService.streamChat(
        messages: conversationHistory,
        config: {
          'temperature': 0.7,
          'max_tokens': 500,
        },
      )) {
        hasReceivedData = true;
        print('Received chunk: $chunk');
        
        if (mounted) {
          setState(() {
            _streamingText += chunk;
            _messages[streamingMessageIndex] = Message(
              text: _streamingText,
              isUser: false,
              timestamp: _messages[streamingMessageIndex].timestamp,
              isStreaming: true,
            );
          });
          _scrollToBottom();
        }
      }

      print('Stream completed. Received data: $hasReceivedData');

      // Mark streaming as complete
      if (mounted) {
        setState(() {
          // If no data was received, show error
          if (!hasReceivedData || _streamingText.isEmpty) {
            _messages[streamingMessageIndex] = Message(
              text: 'لم يتم استلام رد من الخادم. تأكد من أن الخادم يعمل بشكل صحيح.',
              isUser: false,
              timestamp: _messages[streamingMessageIndex].timestamp,
              isStreaming: false,
            );
          } else {
            _messages[streamingMessageIndex] = Message(
              text: _streamingText,
              isUser: false,
              timestamp: _messages[streamingMessageIndex].timestamp,
              isStreaming: false,
            );
          }
          _isLoading = false;
          _streamingText = '';
          
          // Save after receiving bot response
          _saveChatHistory();
        });
      }
    } catch (e) {
      print('Error in streaming: $e');
      
      // Handle error
      if (mounted) {
        setState(() {
          _messages[streamingMessageIndex] = Message(
            text: 'عذراً، حدث خطأ في الاتصال: ${e.toString()}\n\nتأكد من أن الخادم يعمل على: http://localhost:8000',
            isUser: false,
            timestamp: DateTime.now(),
            isStreaming: false,
          );
          _isLoading = false;
          _streamingText = '';
          
          // Save even error messages
          _saveChatHistory();
        });
      }
    }

    _scrollToBottom();
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
                    const Spacer(),
                    // Clear chat button
                    GestureDetector(
                      onTap: _messages.isEmpty ? null : _clearChatHistory,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _messages.isEmpty 
                              ? Colors.white.withOpacity(0.1)
                              : Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.delete_sweep,
                          color: _messages.isEmpty 
                              ? Colors.white.withOpacity(0.3)
                              : Colors.white,
                          size: 20,
                        ),
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
                                    MainAxisAlignment.end,
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
                                        const SizedBox(width: 10),
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
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (message.isUser) ...[
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
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: message.isUser
                          ? Colors.white
                          : Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    textDirection: TextDirection.rtl,
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
          if (!message.isUser) ...[
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
                Icons.support_agent,
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

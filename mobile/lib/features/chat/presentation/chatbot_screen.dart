import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  stt.SpeechToText? _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    // Welcome message
    _messages.add(
      ChatMessage(
        text: "Assalam-o-Alaikum! I am your SecureCity AI Safety Assistant. How can I help you today? You can ask me for first aid steps, safety guidelines, or nearby emergency locations.",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();

    // Trigger AI response simulation (Gemini API integration point)
    await Future.delayed(const Duration(seconds: 1));

    String reply = "I've received your query. In case of immediate physical threat, please press the emergency SOS button on the home screen to contact dispatchers.";

    if (text.toLowerCase().contains('burn')) {
      reply = "First Aid for Burns:\n1. Cool the burn under cold running water for 10-20 minutes.\n2. Do NOT apply ice or butter.\n3. Cover with a clean, non-stick bandage or plastic wrap.\n4. Seek medical attention if it is severe.";
    } else if (text.toLowerCase().contains('earthquake')) {
      reply = "Earthquake Safety Steps:\n1. Drop, Cover, and Hold On under heavy furniture.\n2. Stay away from windows and brick walls.\n3. If outside, find a clear area away from buildings and power lines.";
    }

    if (mounted) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: reply,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    }
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      bool available = await _speech!.initialize(
        onStatus: (val) => debugPrint('STT status: $val'),
        onError: (val) => debugPrint('STT error: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech!.listen(
          onResult: (val) => setState(() {
            _textController.text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech!.stop();
      _sendMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to home',
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.accentCyan,
              radius: 16,
              child: Icon(Icons.support_agent, color: AppColors.primaryDeepBlue, size: 20),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Safety AI Assistant'),
                Text('Online', style: TextStyle(color: AppColors.successGreen, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Chat history
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _ChatBubble(message: msg);
              },
            ),
          ),

          // Suggestions row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _SuggestionChip(
                  label: "First Aid for Burns",
                  onTap: () {
                    _textController.text = "First Aid for Burns";
                    _sendMessage();
                  },
                ),
                _SuggestionChip(
                  label: "Earthquake Safety Steps",
                  onTap: () {
                    _textController.text = "Earthquake Safety Steps";
                    _sendMessage();
                  },
                ),
              ],
            ),
          ),

          // Input field row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.darkCard,
              border: Border(top: BorderSide(color: AppColors.glassWhite10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Type safety query or guidelines...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? AppColors.emergencyRed : AppColors.accentCyan,
                  ),
                  tooltip: _isListening ? 'Stop voice input' : 'Start voice input',
                  onPressed: _toggleListening,
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.accentCyan),
                  tooltip: 'Send message',
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final align = message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = message.isUser ? AppColors.accentCyan : AppColors.darkCard;
    final textColor = message.isUser ? AppColors.primaryDeepBlue : AppColors.darkTextPrimary;
    final border = message.isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          )
        : const BorderRadius.only(
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          );

    return Semantics(
      label: '${message.isUser ? 'You' : 'Assistant'} said: ${message.text}',
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: color,
              borderRadius: border,
              border: Border.all(color: AppColors.glassWhite10),
            ),
            child: Text(
              message.text,
              style: AppTypography.darkBodyMedium.copyWith(color: textColor, height: 1.4),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: AppTypography.darkLabelMedium),
        backgroundColor: AppColors.darkCard,
        side: const BorderSide(color: AppColors.glassBorderLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: onTap,
      ),
    );
  }
}

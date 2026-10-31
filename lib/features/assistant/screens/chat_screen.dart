import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_background.dart';
import '../controllers/chatbot_controller.dart';
import '../widgets/chat_bubble.dart';
import '../../../models/chat_message_model.dart';
import '../../../models/test_result_model.dart';
import '../../../models/sample_type.dart';

class ChatScreen extends StatefulWidget {
  final TestResultModel? context_;
  const ChatScreen({super.key, this.context_});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = ChatbotController();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessageModel> _messages = [];

  @override
  void initState() {
    super.initState();
    final greeting = widget.context_ != null
        ? _controller.buildContextGreeting(
            sampleType: widget.context_!.sampleType.label,
            contaminant: widget.context_!.contaminant,
            isInconclusive: widget.context_!.isInconclusive,
            purityPercent: widget.context_!.purityPercent,
          )
        : 'Hi! I\'m your HIFAZAT assistant. Ask me about water or milk safety.';
    _messages.add(ChatMessageModel(text: greeting, isUser: false));
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessageModel(text: text, isUser: true));
      _messages.add(ChatMessageModel(text: _controller.getAnswer(text), isUser: false));
    });
    _textController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.eco_rounded, size: 20),
            SizedBox(width: 8),
            Text('HIFAZAT Assistant'),
          ],
        ),
      ),
      body: Stack(
        children: [
          const AppBackground(),
          Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => ChatBubble(message: _messages[index]),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Ask about your result...',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Theme.of(context).dividerColor),
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
        ],
      ),
    );
  }
}

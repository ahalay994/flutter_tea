import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/chat_provider.dart';
import '../../providers/chat_state_provider.dart';
import '../../widgets/chat_message_widget.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    ref.read(chatProvider.notifier).sendMessage(text);
    _textController.clear();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Очистить чат'),
          content: const Text('Вы уверены, что хотите очистить историю чата?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                ref.read(chatProvider.notifier).clearChat();
                Navigator.of(context).pop();
              },
              child: const Text('Очистить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final isSending = ref.watch(isSendingProvider);

    // Автоматически прокручиваем вниз при изменении количества сообщений
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (messages.length > 0) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('ИИ-помощник по чаю'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Область сообщений чата
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Text('Задайте вопрос о чае, и ИИ-помощник поможет вам найти информацию'),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return ChatMessageWidget(
                        content: message.content,
                        role: message.role,
                        timestamp: message.timestamp,
                      );
                    },
                  ),
          ),
          
          // Поле ввода
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Задайте вопрос о чае...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !isSending, // Отключаем поле ввода во время отправки
                  ),
                ),
                const SizedBox(width: 8),
                isSending
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      )
                    : FloatingActionButton(
                        onPressed: isSending ? null : _sendMessage, // Отключаем кнопку во время отправки
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        child: const Icon(Icons.send, color: Colors.white),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
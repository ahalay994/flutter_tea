import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/local_database_service.dart';
import 'chat_state_provider.dart';

final chatProvider = NotifierProvider<ChatProvider, List<ChatMessage>>(ChatProvider.new);

class ChatProvider extends Notifier<List<ChatMessage>> {
  final ChatService _chatService = ChatService();
  final LocalDatabaseService _dbService = LocalDatabaseService();
  final String _sessionId = 'chat_session'; // Можно использовать уникальный ID для каждой сессии

  @override
  List<ChatMessage> build() {
    _loadChatHistory();
    return [];
  }

  Future<void> _loadChatHistory() async {
    final history = await _dbService.getChatHistory(_sessionId);
    
    // Преобразуем историю в сообщения для отображения
    final messages = history.map((msg) => ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Используем временный ID
      content: msg['content']!,
      role: msg['role']!,
      timestamp: DateTime.now(), // Для отображения используем текущее время
    )).toList();
    
    state = messages;
  }

  void sendMessage(String text) async {
    // Устанавливаем состояние загрузки
    ref.read(isSendingProvider.notifier).setIsSending(true);

    try {
      // Добавляем сообщение пользователя в локальное состояние
      final userMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: text,
        role: 'user',
        timestamp: DateTime.now(),
      );
      
      state = [...state, userMessage];
      
      // Отправляем сообщение в сервис
      final result = await _chatService.sendMessage(text, state);
      
      final answer = result['answer'] as String?;
      
      if (answer != null) {
        final assistantMessage = ChatMessage(
          id: 'assistant_${DateTime.now().millisecondsSinceEpoch}',
          content: answer,
          role: 'assistant',
          timestamp: DateTime.now(),
        );
        
        // Добавляем ответ ассистента к истории
        final updatedMessages = List<ChatMessage>.from([...state, assistantMessage]);
        
        // Ограничиваем историю последними 20 сообщениями
        if (updatedMessages.length > 20) {
          updatedMessages.removeRange(0, updatedMessages.length - 20);
        }
        
        state = updatedMessages;
        
        // Сохраняем обновленную историю в базу данных
        await _dbService.clearChatHistory(_sessionId);
        for (final message in updatedMessages) {
          await _dbService.saveChatMessage(
            sessionId: _sessionId,
            role: message.role,
            content: message.content,
          );
        }
      }
    } finally {
      // Сбрасываем состояние загрузки
      ref.read(isSendingProvider.notifier).setIsSending(false);
    }
  }

  void addMessage(ChatMessage message) {
    final updatedMessages = List<ChatMessage>.from([...state, message]);
    
    // Ограничиваем историю последними 20 сообщениями
    if (updatedMessages.length > 20) {
      updatedMessages.removeRange(0, updatedMessages.length - 20);
    }
    
    state = updatedMessages;
  }

  void updateLastMessage(String content) {
    if (state.isEmpty) return;
    
    final updatedMessages = List<ChatMessage>.from(state);
    final lastMessage = updatedMessages.last;
    final updatedMessage = lastMessage.copyWith(content: content);
    updatedMessages[updatedMessages.length - 1] = updatedMessage;
    
    // Ограничиваем историю последними 20 сообщениями
    if (updatedMessages.length > 20) {
      updatedMessages.removeRange(0, updatedMessages.length - 20);
    }
    
    state = updatedMessages;
  }

  void clearChat() async {
    state = [];
    await _dbService.clearChatHistory(_sessionId);
  }
}
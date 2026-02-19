import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:tea/utils/app_config.dart';
import '../models/chat_message.dart';

class ChatService {
  String get _baseUrl {
    String? envValue = const String.fromEnvironment('API_URL', defaultValue: '');
    if (envValue.isNotEmpty) return envValue;

    try {
      // Пытаемся получить из dotenv, если доступно
      String? dotenvValue = dotenv.env['API_URL'];
      return dotenvValue ?? AppConfig.apiUrl;
    } catch (e) {
      // Если возникла ошибка доступа к dotenv (например, веб), используем AppConfig
      return AppConfig.apiUrl;
    }
  }

  Future<Map<String, dynamic>> sendMessage(String text, List<ChatMessage> history) async {
    final client = http.Client();
    
    // Добавляем '/chat' к базовому URL, так как эндпоинт /api/chat
    String chatUrl = '$_baseUrl/chat';
    
    // Преобразуем историю в формат, подходящий для отправки
    List<Map<String, String>> historyForSend = history.map((msg) => {
      'role': msg.role,
      'content': msg.content,
    }).toList();
    
    // Логируем данные, которые отправляются на сервер
    print('Отправка данных на эндпоинт: $chatUrl');
    print('Сообщение пользователя: $text');
    print('История чата: $historyForSend');
    
    final request = http.Request('POST', Uri.parse(chatUrl));

    request.headers.addAll({
      'Content-Type': 'application/json',
    });

    final requestBody = {
      "message": text,
      "history": historyForSend,
    };
    
    // Логируем тело запроса
    print('Тело запроса: ${jsonEncode(requestBody)}');
    
    request.body = jsonEncode(requestBody);

    try {
      // Отправляем запрос и получаем ответ
      final response = await client.send(request);
      final responseBody = await response.stream.bytesToString();
      
      print('Получен ответ от сервера, статус: ${response.statusCode}');
      print('Тело ответа: $responseBody');
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(responseBody);
        return decoded;
      } else {
        print('Ошибка запроса: ${response.statusCode} - ${response.reasonPhrase}');
        return {
          'answer': 'Произошла ошибка при обработке запроса',
          'updatedHistory': historyForSend,
        };
      }
    } catch (e) {
      print('Ошибка соединения: $e');
      return {
        'answer': 'Ошибка соединения с сервером',
        'updatedHistory': historyForSend,
      };
    } finally {
      client.close();
    }
  }
}

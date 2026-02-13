import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'responses/api_response.dart';

abstract class Api {
  final String _baseUrl = dotenv.env['API_URL'] ?? '';

  // Базовый GET (ваш существующий)
  Future<ApiResponse> getRequest(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl$endpoint'));
      return _processResponse(response);
    } catch (e) {
      return ApiResponse(ok: false, message: 'Ошибка сети: $e');
    }
  }

  // POST запрос для обычных данных (JSON)
  Future<ApiResponse> postRequest(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      return _processResponse(response);
    } catch (e) {
      return ApiResponse(ok: false, message: 'Ошибка запроса: $e');
    }
  }

  // POST запрос для отправки файлов (Multipart)
  Future<ApiResponse> postMultipartRequest({
    required String endpoint,
    required Map<String, String> fields, // Сюда текстовые поля
    List<http.MultipartFile>? files, // Сюда подготовленные файлы
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);

      // Добавляем текстовые поля
      request.fields.addAll(fields);

      // Добавляем файлы
      if (files != null) {
        request.files.addAll(files);
      }

      // Устанавливаем заголовки
      // ВАЖНО: Не устанавливаем Content-Type вручную, т.к. multipart-запрос сам устанавливает его с boundary
      request.headers.addAll({
        'Accept': 'application/json',
      });

      print('Отправляем multipart-запрос на: $uri');
      print('Количество файлов: ${files?.length ?? 0}');
      print('Количество текстовых полей: ${fields.length}');
      print('Заголовки запроса: ${request.headers}');
      // Проверяем Content-Type после создания запроса (boundary добавится после вызова finalize())
      if (request.contentLength != null) {
        print('Content-Length: ${request.contentLength}');
      }
      if (files != null) {
        for (int i = 0; i < files.length; i++) {
          print('Файл ${i + 1}: имя=${files[i].filename}, длина=${files[i].length}, поле=${files[i].field}');
        }
      }

      final streamedResponse = await request.send();
      print('Получен streamedResponse с.statusCode: ${streamedResponse.statusCode}');
      
      final response = await http.Response.fromStream(streamedResponse);
      print('Получен финальный response с.statusCode: ${response.statusCode}');
      print('Тело ответа: ${response.body}');

      return _processResponse(response);
    } catch (e) {
      print('Ошибка при отправке multipart-запроса: $e');
      return ApiResponse(ok: false, message: 'Ошибка загрузки: $e');
    }
  }

  // Общий метод обработки ответа, чтобы не дублировать код
  ApiResponse _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      return ApiResponse.fromJson(decoded);
    } else {
      // Добавляем тело ошибки в сообщение для лучшей отладки
      String errorMessage = 'Ошибка сервера: ${response.statusCode}';
      try {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        // Пытаемся получить сообщение об ошибке из тела ответа
        if (errorBody is Map<String, dynamic> && errorBody['message'] != null) {
          errorMessage = errorBody['message'].toString();
        } else if (errorBody is String) {
          errorMessage = errorBody;
        } else {
          // В противном случае, просто добавляем тело ответа к сообщению
          errorMessage += ', тело ответа: ${response.body}';
        }
      } catch (e) {
        // Если не удалось распарсить тело ошибки, добавляем его как строку
        errorMessage += ', тело ответа: ${response.body}';
      }
      return ApiResponse(ok: false, message: errorMessage);
    }
  }
}

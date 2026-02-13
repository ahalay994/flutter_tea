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

  // DELETE запрос
  Future<ApiResponse> deleteRequest(String endpoint) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl$endpoint'));
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
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl$endpoint'));

      // Добавляем текстовые поля
      request.fields.addAll(fields);

      // Добавляем файлы
      if (files != null) {
        request.files.addAll(files);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _processResponse(response);
    } catch (e) {
      return ApiResponse(ok: false, message: 'Ошибка загрузки: $e');
    }
  }

  // Общий метод обработки ответа, чтобы не дублировать код
  ApiResponse _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        return ApiResponse.fromJson(decoded);
      } catch (e) {
        // Если тело ответа пустое или не является JSON, создаем ApiResponse вручную
        if (response.statusCode == 204) {
          return ApiResponse(ok: true, message: 'Успешно', data: null);
        }
        return ApiResponse(
          ok: response.statusCode >= 200 && response.statusCode < 300,
          message: 'Ответ сервера',
          data: response.body,
        );
      }
    } else {
      return ApiResponse(ok: false, message: 'Ошибка сервера: ${response.statusCode}');
    }
  }
}

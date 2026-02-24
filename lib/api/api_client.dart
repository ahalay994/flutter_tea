import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:tea/utils/app_config.dart';
import 'package:tea/utils/app_logger.dart';

import 'responses/api_response.dart';

abstract class Api {
  String get _baseUrl {
    // Проверяем переменные окружения Dart в первую очередь
    String? envValue = String.fromEnvironment('API_URL', defaultValue: '');
    if (envValue.isNotEmpty) {
      AppLogger.debug('Используем API_URL из String.fromEnvironment: $envValue');
      return envValue;
    }
    
    // Затем пробуем получить из flutter_dotenv
    try {
      String? dotenvValue = dotenv.env['API_URL'];
      if (dotenvValue != null && dotenvValue.isNotEmpty) {
        AppLogger.debug('Используем API_URL из dotenv: $dotenvValue');
        return dotenvValue;
      }
    } catch (e) {
      AppLogger.debug('Ошибка получения API_URL из dotenv: $e');
      // Если возникла ошибка доступа к dotenv, продолжаем
    }
    
    // Наконец, используем AppConfig
    String fallbackUrl = AppConfig.apiUrl;
    AppLogger.debug('Используем API_URL из AppConfig: $fallbackUrl');
    return fallbackUrl;
  }

  // Базовый GET (ваш существующий)
  Future<ApiResponse> getRequest(String endpoint) async {
    try {
      AppLogger.debug('Выполняем GET запрос: $_baseUrl$endpoint');
      final response = await http.get(Uri.parse('$_baseUrl$endpoint'));
      AppLogger.debug('Получен ответ: ${response.statusCode}');
      return _processResponse(response);
    } catch (e) {
      AppLogger.error('Ошибка GET запроса к $_baseUrl$endpoint', error: e);
      return ApiResponse(ok: false, message: 'Ошибка сети: $e');
    }
  }

  // POST запрос для обычных данных (JSON)
  Future<ApiResponse> postRequest(String endpoint, Map<String, dynamic> data) async {
    try {
      AppLogger.debug('Выполняем POST запрос: $_baseUrl$endpoint');
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      AppLogger.debug('Получен ответ: ${response.statusCode}');
      return _processResponse(response);
    } catch (e) {
      AppLogger.error('Ошибка POST запроса к $_baseUrl$endpoint', error: e);
      return ApiResponse(ok: false, message: 'Ошибка запроса: $e');
    }
  }

  // PUT запрос для обновления данных (JSON)
  Future<ApiResponse> putRequest(String endpoint, Map<String, dynamic> data) async {
    try {
      // Логируем отправляемые данные
      AppLogger.debug('PUT запрос к $endpoint с данными: ${json.encode(data)}');
      
      final response = await http.put(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      AppLogger.debug('Ответ сервера: ${response.statusCode}, тело: ${response.body}');
      return _processResponse(response);
    } catch (e) {
      AppLogger.error('Ошибка PUT запроса к $_baseUrl$endpoint', error: e);
      return ApiResponse(ok: false, message: 'Ошибка запроса: $e');
    }
  }

  // DELETE запрос
  Future<ApiResponse> deleteRequest(String endpoint) async {
    try {
      AppLogger.debug('Выполняем DELETE запрос: $_baseUrl$endpoint');
      final response = await http.delete(Uri.parse('$_baseUrl$endpoint'));
      AppLogger.debug('Получен ответ: ${response.statusCode}');
      return _processResponse(response);
    } catch (e) {
      AppLogger.error('Ошибка DELETE запроса к $_baseUrl$endpoint', error: e);
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
      AppLogger.debug('Выполняем POST multipart запрос: $_baseUrl$endpoint');
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl$endpoint'));

      // Добавляем текстовые поля
      request.fields.addAll(fields);

      // Добавляем файлы
      if (files != null) {
        request.files.addAll(files);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      AppLogger.debug('Получен ответ: ${response.statusCode}');
      return _processResponse(response);
    } catch (e) {
      AppLogger.error('Ошибка POST multipart запроса к $_baseUrl$endpoint', error: e);
      return ApiResponse(ok: false, message: 'Ошибка загрузки: $e');
    }
  }

  // Общий метод обработки ответа, чтобы не дублировать код
  ApiResponse _processResponse(http.Response response) {
    AppLogger.debug('Обработка ответа: статус ${response.statusCode}, тело: ${response.body}');
    
    try {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      
      // Проверяем, есть ли поле ok в ответе и используем его для определения успешности
      if (decoded is Map<String, dynamic>) {
        final ok = decoded['ok'] as bool? ?? (response.statusCode >= 200 && response.statusCode < 300);
        final message = decoded['message'] as String? ?? (ok ? 'Успешно' : 'Ошибка сервера: ${response.statusCode}');
        final data = decoded['data'];
        
        if (!ok) {
          AppLogger.error('Ответ сервера содержит ошибку: $message');
        }
        
        return ApiResponse(ok: ok, message: message, data: data);
      } else {
        // Если ответ не в формате JSON или не содержит поле ok, используем статус код
        if (response.statusCode >= 200 && response.statusCode < 300) {
          if (response.statusCode == 204) {
            return ApiResponse(ok: true, message: 'Успешно', data: null);
          }
          return ApiResponse(ok: response.statusCode >= 200 && response.statusCode < 300, message: 'Ответ сервера', data: response.body);
        } else {
          AppLogger.error('Ошибка сервера: ${response.statusCode}, тело: ${response.body}');
          return ApiResponse(ok: false, message: 'Ошибка сервера: ${response.statusCode}', data: response.body);
        }
      }
    } catch (e) {
      // Если не удается распарсить JSON, используем статус код
      AppLogger.error('Ошибка парсинга JSON ответа: $e');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.statusCode == 204) {
          return ApiResponse(ok: true, message: 'Успешно', data: null);
        }
        return ApiResponse(ok: response.statusCode >= 200 && response.statusCode < 300, message: 'Ответ сервера', data: response.body);
      } else {
        return ApiResponse(ok: false, message: 'Ошибка сервера: ${response.statusCode}', data: response.body);
      }
    }
  }
}
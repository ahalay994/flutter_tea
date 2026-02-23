import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:tea_multitenant/utils/app_config.dart';
import 'package:tea_multitenant/utils/app_logger.dart';

import 'responses/api_response.dart';

abstract class Api {
  String get _baseUrl {
    String? envValue = const String.fromEnvironment('API_URL', defaultValue: '');
    if (envValue.isNotEmpty) {
      AppLogger.debug('Базовый URL из переменной окружения: $envValue');
      return envValue;
    }
    
    try {
      // Пытаемся получить из dotenv, если доступно
      String? dotenvValue = dotenv.env['API_URL'];
      final baseUrl = dotenvValue ?? AppConfig.apiUrl;
      AppLogger.debug('Базовый URL из .env или AppConfig: $baseUrl');
      return baseUrl;
    } catch (e) {
      // Если возникла ошибка доступа к dotenv (например, в вебе), используем AppConfig
      AppLogger.debug('Ошибка доступа к .env, используем AppConfig: ${AppConfig.apiUrl}');
      return AppConfig.apiUrl;
    }
  }

  // Базовый GET (ваш существующий)
  Future<ApiResponse> getRequest(String endpoint) async {
    final fullUrl = '$_baseUrl$endpoint';
    AppLogger.debug('GET запрос: $fullUrl');
    
    try {
      final response = await http.get(Uri.parse(fullUrl));
      AppLogger.debug('Ответ: статус ${response.statusCode}');
      return _processResponse(response);
    } catch (e) {
      AppLogger.error('Ошибка GET запроса к $fullUrl: $e');
      return ApiResponse(ok: false, message: 'Ошибка сети: $e');
    }
  }

  // POST запрос для обычных данных (JSON)
  Future<ApiResponse> postRequest(String endpoint, Map<String, dynamic> data) async {
    final fullUrl = '$_baseUrl$endpoint';
    AppLogger.debug('POST запрос: $fullUrl с данными: ${json.encode(data)}');
    
    try {
      final response = await http.post(
        Uri.parse(fullUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      AppLogger.debug('Ответ POST: ${response.statusCode}');
      return _processResponse(response);
    } catch (e) {
      AppLogger.error('Ошибка POST запроса к $fullUrl: $e');
      return ApiResponse(ok: false, message: 'Ошибка запроса: $e');
    }
  }

  // PUT запрос для обновления данных (JSON)
  Future<ApiResponse> putRequest(String endpoint, Map<String, dynamic> data) async {
    final fullUrl = '$_baseUrl$endpoint';
    // Логируем отправляемые данные
    AppLogger.debug('PUT запрос к $fullUrl с данными: ${json.encode(data)}');
    
    try {
      final response = await http.put(
        Uri.parse(fullUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      AppLogger.debug('Ответ сервера: ${response.statusCode}, тело: ${response.body}');
      return _processResponse(response);
    } catch (e) {
      AppLogger.error('Ошибка PUT запроса к $fullUrl: $e');
      return ApiResponse(ok: false, message: 'Ошибка запроса: $e');
    }
  }

  // DELETE запрос
  Future<ApiResponse> deleteRequest(String endpoint) async {
    final fullUrl = '$_baseUrl$endpoint';
    AppLogger.debug('DELETE запрос: $fullUrl');
    
    try {
      final response = await http.delete(Uri.parse(fullUrl));
      AppLogger.debug('Ответ DELETE: ${response.statusCode}');
      return _processResponse(response);
    } catch (e) {
      AppLogger.error('Ошибка DELETE запроса к $fullUrl: $e');
      return ApiResponse(ok: false, message: 'Ошибка запроса: $e');
    }
  }

  // POST запрос для отправки файлов (Multipart)
  Future<ApiResponse> postMultipartRequest({
    required String endpoint,
    required Map<String, String> fields, // Сюда текстовые поля
    List<http.MultipartFile>? files, // Сюда подготовленные файлы
  }) async {
    final fullUrl = '$_baseUrl$endpoint';
    AppLogger.debug('Multipart POST запрос: $fullUrl с полями: $fields');
    
    try {
      final request = http.MultipartRequest('POST', Uri.parse(fullUrl));

      // Добавляем текстовые поля
      request.fields.addAll(fields);

      // Добавляем файлы
      if (files != null) {
        request.files.addAll(files);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      AppLogger.debug('Ответ Multipart: ${response.statusCode}');

      return _processResponse(response);
    } catch (e) {
      AppLogger.error('Ошибка Multipart запроса к $fullUrl: $e');
      return ApiResponse(ok: false, message: 'Ошибка загрузки: $e');
    }
  }

  // Общий метод обработки ответа, чтобы не дублировать код
  ApiResponse _processResponse(http.Response response) {
    try {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      
      // Проверяем, есть ли поле ok в ответе и используем его для определения успешности
      if (decoded is Map<String, dynamic>) {
        final ok = decoded['ok'] as bool? ?? (response.statusCode >= 200 && response.statusCode < 300);
        final message = decoded['message'] as String? ?? (ok ? 'Успешно' : 'Ошибка сервера: ${response.statusCode}');
        final data = decoded['data'];
        
        return ApiResponse(ok: ok, message: message, data: data);
      } else {
        // Если ответ не в формате JSON или не содержит поле ok, используем статус код
        if (response.statusCode >= 200 && response.statusCode < 300) {
          if (response.statusCode == 204) {
            return ApiResponse(ok: true, message: 'Успешно', data: null);
          }
          return ApiResponse(ok: response.statusCode >= 200 && response.statusCode < 300, message: 'Ответ сервера', data: response.body);
        } else {
          return ApiResponse(ok: false, message: 'Ошибка сервера: ${response.statusCode}', data: response.body);
        }
      }
    } catch (e) {
      // Если не удается распарсить JSON, используем статус код
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
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'responses/api_response.dart';

abstract class Api {
  final String _baseUrl = dotenv.env['API_URL'] ?? '';

  Future<ApiResponse> getRequest(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl$endpoint'));

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));

        return ApiResponse.fromJson(decoded);
      } else {
        return ApiResponse(ok: false, message: 'Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse(ok: false, message: 'Ошибка сети: $e');
    }
  }
}

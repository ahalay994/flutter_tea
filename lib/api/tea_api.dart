import 'package:tea/api/api_client.dart';
import 'package:tea/api/dto/create_tea_dto.dart';
import 'package:tea/api/responses/tea_response.dart';
import 'package:tea/api/responses/api_response.dart';

// Структура для ответа с пагинацией
class PaginatedTeaResponse {
  final List<TeaResponse> data;
  final int currentPage;
  final int totalPages;
  final int perPage;
  final bool hasMore;

  PaginatedTeaResponse({
    required this.data,
    required this.currentPage,
    required this.totalPages,
    required this.perPage,
    required this.hasMore,
  });

  factory PaginatedTeaResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List;
    final data = dataList.map((item) => TeaResponse.fromJson(item as Map<String, dynamic>)).toList();
    
    return PaginatedTeaResponse(
      data: data,
      currentPage: json['pagination']['currentPage'] as int? ?? 1,
      totalPages: json['pagination']['totalPages'] as int? ?? 1,
      perPage: json['pagination']['perPage'] as int? ?? 10,
      hasMore: json['pagination']['hasMore'] as bool? ?? false,
    );
  }
}

class TeaApi extends Api {
  Future<List<TeaResponse>> getTeas() async {
    final response = await getRequest('/tea');

    if (response.ok) {
      return (response.data as List).map((json) => TeaResponse.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception(response.message ?? "Ошибка при получении списка чаёв");
    }
  }
  
  // Метод для получения чаёв с пагинацией
  Future<PaginatedTeaResponse> getTeasPaginated({int page = 1, int perPage = 10}) async {
    final response = await getRequest('/tea');

    if (response.ok) {
      // Если сервер возвращает просто список, оборачиваем его в объект пагинации
      if (response.data is List) {
        final dataList = response.data as List;
        final teas = dataList.map((item) => TeaResponse.fromJson(item as Map<String, dynamic>)).toList();
        
        return PaginatedTeaResponse(
          data: teas,
          currentPage: page,
          totalPages: 1, // Временно устанавливаем 1, пока не будет настоящей пагинации
          perPage: perPage,
          hasMore: false, // Временно false
        );
      } else if (response.data is Map<String, dynamic>) {
        // Если сервер возвращает объект с пагинацией
        return PaginatedTeaResponse.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception("Неправильный формат данных");
      }
    } else {
      throw Exception(response.message ?? "Ошибка при получении списка чаёв с пагинацией");
    }
  }

  Future<List<TeaResponse>> saveTea(CreateTeaDto data) async {
    final response = await postRequest('/tea', data.toJson());

    if (response.ok) {
      final rawData = response.data;
      if (rawData is List) {
        return rawData.map((json) => TeaResponse.fromJson(json as Map<String, dynamic>)).toList();
      } else if (rawData != null) {
        // Если бэкенд вернул один объект, оборачиваем его в список
        return [TeaResponse.fromJson(rawData as Map<String, dynamic>)];
      }
      // Если бэкенд вернул успех, но без данных (например, статус 204)
      return [];
    } else {
      throw Exception(response.message ?? "Ошибка при сохранении чая");
    }
  }
  
  // Новый метод для обновления чая
  Future<void> updateTea(int teaId, CreateTeaDto data) async {
    final response = await putRequest('/tea/$teaId', data.toJson());
    
    if (!response.ok) {
      // Выводим более подробную информацию об ошибке
      String errorMessage = response.message ?? "Ошибка при обновлении чая";
      if (response.data != null) {
        errorMessage += "\nДополнительная информация: ${response.data}";
      }
      throw Exception(errorMessage);
    }
  }
  
  Future<ApiResponse> deleteTea(int teaId) async {
    final response = await deleteRequest('/tea/$teaId');
    return response;
  }
  
  // Метод для получения чая по ID
  Future<TeaResponse> getTea(int teaId) async {
    final response = await getRequest('/tea/$teaId');
    
    if (response.ok && response.data != null) {
      return TeaResponse.fromJson(response.data as Map<String, dynamic>);
    } else {
      throw Exception(response.message ?? "Ошибка при получении чая");
    }
  }
}
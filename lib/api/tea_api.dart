import 'package:tea_multitenant/api/api_client.dart';
import 'package:tea_multitenant/api/dto/create_tea_dto.dart';
import 'package:tea_multitenant/api/responses/tea_response.dart';
import 'package:tea_multitenant/api/responses/api_response.dart';
import 'package:tea_multitenant/api/responses/facet_response.dart';
import 'package:tea_multitenant/utils/app_logger.dart';

// Структура для ответа с пагинацией
class PaginatedTeaResponse {
  final List<TeaResponse> data;
  final int currentPage;
  final int totalPages;
  final int perPage;
  final bool hasMore;
  final int totalCount; // Добавляем поле totalCount

  PaginatedTeaResponse({
    required this.data,
    required this.currentPage,
    required this.totalPages,
    required this.perPage,
    required this.hasMore,
    required this.totalCount, // Добавляем totalCount в конструктор
  });

  factory PaginatedTeaResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List;
    final data = dataList.map((item) => TeaResponse.fromJson(item as Map<String, dynamic>)).toList();
    
    // Проверяем, есть ли объект pagination
    Map<String, dynamic>? pagination;
    if (json['pagination'] != null && json['pagination'] is Map) {
      pagination = json['pagination'] as Map<String, dynamic>;
    } else {
      // Если pagination нет, используем значения по умолчанию
      return PaginatedTeaResponse(
        data: data,
        currentPage: json['currentPage'] as int? ?? 1,
        totalPages: json['totalPages'] as int? ?? 1,
        perPage: json['perPage'] as int? ?? 10,
        hasMore: json['hasMore'] as bool? ?? false,
        totalCount: json['totalCount'] as int? ?? 0, // Используем totalCount из основного объекта
      );
    }
    
    return PaginatedTeaResponse(
      data: data,
      currentPage: pagination['currentPage'] as int? ?? 1,
      totalPages: pagination['totalPages'] as int? ?? 1,
      perPage: pagination['perPage'] as int? ?? 10,
      hasMore: pagination['hasMore'] as bool? ?? false,
      totalCount: pagination['totalCount'] as int? ?? 0, // Используем totalCount из объекта pagination
    );
  }
}

class TeaApi extends Api {
  Future<List<TeaResponse>> getTeas(String deviceId) async {
    final response = await getRequest('/device-tea?deviceId=$deviceId');

    if (response.ok) {
      return (response.data as List).map((json) => TeaResponse.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception(response.message ?? "Ошибка при получении списка чаёв");
    }
  }
  


  Future<List<TeaResponse>> saveTea(CreateTeaDto data, String deviceId) async {
    final response = await postRequest('/device-tea?deviceId=$deviceId', data.toJson());

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
  
  // Метод для получения отфильтрованных чаёв с пагинацией
  Future<PaginatedTeaResponse> getFilteredTeas(Map<String, dynamic> filterParams, String deviceId) async {
    // Формируем query параметры
    final queryParams = <String, String>{};
    
    if (filterParams['search'] != null) {
      queryParams['search'] = filterParams['search'].toString();
    }
    
    if (filterParams['countries'] != null) {
      queryParams['countries'] = filterParams['countries'].toString();
    }
    
    if (filterParams['types'] != null) {
      queryParams['types'] = filterParams['types'].toString();
    }
    
    if (filterParams['appearances'] != null) {
      queryParams['appearances'] = filterParams['appearances'].toString();
    }
    
    if (filterParams['flavors'] != null) {
      queryParams['flavors'] = filterParams['flavors'].toString();
    }
    
    // Добавляем пагинацию
    queryParams['page'] = (filterParams['page'] ?? 1).toString();
    queryParams['perPage'] = (filterParams['perPage'] ?? 10).toString();
    
    // Добавляем deviceId
    queryParams['deviceId'] = deviceId;
    
    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    // Логируем URL и параметры запроса
    AppLogger.debug('Запрос к эндпоинту: /device-tea/pagination?$queryString');
    AppLogger.debug('deviceId: $deviceId');
    AppLogger.debug('Формируемый URL: /device-tea/pagination?$queryString');
    
    try {
      final response = await getRequest('/device-tea/pagination?$queryString');
      
      AppLogger.debug('Ответ от сервера: ok=${response.ok}, message=${response.message}');
      if (response.data != null) {
        AppLogger.debug('Данные ответа: ${response.data}');
      }

      if (response.ok) {
        // Если сервер возвращает объект с пагинацией
        if (response.data is Map<String, dynamic>) {
          return PaginatedTeaResponse.fromJson(response.data as Map<String, dynamic>);
        } else if (response.data is List) {
          // Если сервер возвращает просто список, создаем объект пагинации
          final dataList = response.data as List;
          final teas = dataList.map((item) => TeaResponse.fromJson(item as Map<String, dynamic>)).toList();
          
          return PaginatedTeaResponse(
            data: teas,
            currentPage: int.tryParse(queryParams['page'] ?? '1') ?? 1,
            totalPages: 1, // Временно, пока не будет настоящей пагинации от сервера
            perPage: int.tryParse(queryParams['perPage'] ?? '10') ?? 10,
            hasMore: false, // Временно false
            totalCount: teas.length, // Устанавливаем totalCount как длину списка
          );
        } else {
          throw Exception("Неправильный формат данных");
        }
      } else {
        throw Exception(response.message ?? "Ошибка при получении отфильтрованного списка чаёв");
      }
    } catch (e) {
      AppLogger.error('Ошибка при запросе к /device-tea/pagination: $e');
      rethrow;
    }
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



// Метод для получения фасетов (количество чаёв по каждому фильтру)
extension TeaApiFacets on TeaApi {
  Future<FacetResponse> getFacets(Map<String, dynamic> filterParams, String deviceId) async {
    // Формируем query параметры
    final queryParams = <String, String>{};
    
    if (filterParams['search'] != null) {
      queryParams['search'] = filterParams['search'].toString();
    }
    
    if (filterParams['countries'] != null) {
      queryParams['countries'] = filterParams['countries'].toString();
    }
    
    if (filterParams['types'] != null) {
      queryParams['types'] = filterParams['types'].toString();
    }
    
    if (filterParams['appearances'] != null) {
      queryParams['appearances'] = filterParams['appearances'].toString();
    }
    
    if (filterParams['flavors'] != null) {
      queryParams['flavors'] = filterParams['flavors'].toString();
    }
    
    // Добавляем deviceId
    queryParams['deviceId'] = deviceId;
    
    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    final response = await getRequest('/device-tea/facets${queryString.isNotEmpty ? '?$queryString' : ''}');

    if (response.ok && response.data != null) {
      return FacetResponse.fromJson(response.data as Map<String, dynamic>);
    } else {
      throw Exception(response.message ?? "Ошибка при получении фасетов");
    }
  }
}
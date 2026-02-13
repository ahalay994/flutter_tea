import 'package:tea/api/api_client.dart';
import 'package:tea/api/dto/create_tea_dto.dart';
import 'package:tea/api/responses/tea_response.dart';
import 'package:tea/api/responses/api_response.dart';

class TeaApi extends Api {
  Future<List<TeaResponse>> getTeas() async {
    final response = await getRequest('/tea');

    if (response.ok) {
      return (response.data as List).map((json) => TeaResponse.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception(response.message ?? "Ошибка при получении списка чаёв");
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
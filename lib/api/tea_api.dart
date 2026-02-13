import 'package:tea/api/api_client.dart';
import 'package:tea/api/dto/create_tea_dto.dart';
import 'package:tea/utils/app_logger.dart';

import 'responses/tea_response.dart';

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
    AppLogger.debug('Отправляем DTO для сохранения чая с ${data.images.length} изображениями');

    final response = await postRequest('/tea', data.toJson());

    if (response.ok) {
      final rawData = response.data;
      if (rawData is List) {
        AppLogger.success('Чай успешно сохранен, получено ${rawData.length} ответов');
        return rawData.map((json) => TeaResponse.fromJson(json as Map<String, dynamic>)).toList();
      }
      // Если бэкенд вернул успех, но без списка (например, один объект или статус 204)
      AppLogger.success('Чай успешно сохранен');
      return [];
    } else {
      AppLogger.error('Ошибка при сохранении чая: ${response.message}');
      throw Exception(response.message ?? "Ошибка при сохранении чая");
    }
  }
}

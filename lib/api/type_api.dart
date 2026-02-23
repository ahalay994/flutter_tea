import 'package:tea_multitenant/api/api_client.dart';

import 'responses/type_response.dart';

class TypeApi extends Api {
  Future<List<TypeResponse>> getTypes() async {
    final response = await getRequest('/type');

    if (response.ok) {
      return (response.data as List).map((json) => TypeResponse.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception(response.message ?? "Ошибка при загрузке типов чая");
    }
  }
}

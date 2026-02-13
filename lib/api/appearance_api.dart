import 'package:tea/api/api_client.dart';

import 'responses/appearance_response.dart';

class AppearanceApi extends Api {
  Future<List<AppearanceResponse>> getAppearances() async {
    final response = await getRequest('/appearance');

    if (response.ok) {
      return (response.data as List).map((json) => AppearanceResponse.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception(response.message ?? "Ошибка при загрузке внешних видов");
    }
  }
}

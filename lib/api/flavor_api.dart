import 'package:tea_multitenant/api/api_client.dart';

import 'responses/flavor_response.dart';

class FlavorApi extends Api {
  Future<List<FlavorResponse>> getFlavors() async {
    final response = await getRequest('/flavor');

    if (response.ok) {
      return (response.data as List).map((json) => FlavorResponse.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception(response.message ?? "Ошибка при загрузке вкусов");
    }
  }
}

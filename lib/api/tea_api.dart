import 'package:tea/api/api_client.dart';

import 'responses/tea_response.dart';

class TeaApi extends Api {
  Future<List<TeaResponse>> getTeas() async {
    final response = await getRequest('/tea');

    if (response.ok) {
      return (response.data as List).map((json) => TeaResponse.fromJson(json as Map<String, dynamic>)).toList();
    }

    return [];
  }
}

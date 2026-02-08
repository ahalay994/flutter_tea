import 'package:tea/api/api_client.dart';

import 'responses/type_response.dart';

class TypeApi extends Api {
  Future<List<TypeResponse>> getTypes() async {
    final response = await getRequest('/appearance');

    if (response.ok) {
      return (response.data as List).map((json) => TypeResponse.fromJson(json as Map<String, dynamic>)).toList();
    }

    return [];
  }
}

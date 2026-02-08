import 'package:tea/api/api_client.dart';

import 'responses/flavor_response.dart';

class FlavorApi extends Api {
  Future<List<FlavorResponse>> getFlavors() async {
    final response = await getRequest('/appearance');

    if (response.ok) {
      return (response.data as List).map((json) => FlavorResponse.fromJson(json as Map<String, dynamic>)).toList();
    }

    return [];
  }
}

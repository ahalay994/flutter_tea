import 'package:tea/api/api_client.dart';

import 'responses/country_response.dart';

class CountryApi extends Api {
  Future<List<CountryResponse>> getCountries() async {
    final response = await getRequest('/appearance');

    if (response.ok) {
      return (response.data as List).map((json) => CountryResponse.fromJson(json as Map<String, dynamic>)).toList();
    }

    return [];
  }
}

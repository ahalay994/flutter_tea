import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tea/api/appearance_api.dart';
import 'package:tea/api/country_api.dart';
import 'package:tea/api/flavor_api.dart';
import 'package:tea/api/responses/appearance_response.dart';
import 'package:tea/api/responses/country_response.dart';
import 'package:tea/api/responses/flavor_response.dart';
import 'package:tea/api/responses/tea_response.dart';
import 'package:tea/api/responses/type_response.dart';
import 'package:tea/api/tea_api.dart';
import 'package:tea/api/type_api.dart';
import 'package:tea/models/tea.dart';
import 'package:tea/utils/app_logger.dart';

import '../providers/metadata_provider.dart';

class TeaController {
  final AppearanceApi _appearanceApi = AppearanceApi();
  final CountryApi _countryApi = CountryApi();
  final FlavorApi _flavorApi = FlavorApi();
  final TypeApi _typeApi = TypeApi();
  final TeaApi _teaApi = TeaApi();

  Future<List<TeaModel>> fetchFullTeas(WidgetRef ref) async {
    try {
      // Запускаем все запросы параллельно
      final results = await Future.wait([
        _appearanceApi.getAppearances(),
        _countryApi.getCountries(),
        _flavorApi.getFlavors(),
        _typeApi.getTypes(),
        _teaApi.getTeas(),
      ]);

      // Раскладываем результаты по переменным с приведением типов
      final List<AppearanceResponse> appearances = results[0] as List<AppearanceResponse>;
      final List<CountryResponse> countries = results[1] as List<CountryResponse>;
      final List<FlavorResponse> flavors = results[2] as List<FlavorResponse>;
      final List<TypeResponse> types = results[3] as List<TypeResponse>;
      final List<TeaResponse> teaResponses = results[4] as List<TeaResponse>;

      // СОХРАНЯЕМ В СТОР для использования в AddScreen
      ref.read(metadataProvider.notifier).state = TeaMetadata(
        appearances: appearances,
        countries: countries,
        flavors: flavors,
        types: types,
      );

      // Мапим каждый TeaResponse в готовую TeaModel
      final fullTeas = teaResponses.map((tea) {
        return TeaModel.fromResponse(
          response: tea,
          countries: countries,
          types: types,
          appearances: appearances,
          flavors: flavors,
        );
      }).toList();

      AppLogger.success('Загружено ${fullTeas.length} чаёв с полными данными');
      return fullTeas;
    } catch (e, stack) {
      AppLogger.error('Ошибка в TeaController', error: e, stackTrace: stack);
      rethrow;
    }
  }
}

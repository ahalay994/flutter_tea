import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tea/api/appearance_api.dart';
import 'package:tea/api/country_api.dart';
import 'package:tea/api/dto/create_tea_dto.dart';
import 'package:tea/api/flavor_api.dart';
import 'package:tea/api/responses/appearance_response.dart';
import 'package:tea/api/responses/country_response.dart';
import 'package:tea/api/responses/flavor_response.dart';
import 'package:tea/api/responses/tea_response.dart';
import 'package:tea/api/responses/type_response.dart';
import 'package:tea/api/tea_api.dart';
import 'package:tea/api/type_api.dart';
import 'package:tea/models/tea.dart';
import 'package:tea/providers/metadata_provider.dart';
import 'package:tea/utils/app_logger.dart';

class TeaService {
  final AppearanceApi _appearanceApi = AppearanceApi();
  final CountryApi _countryApi = CountryApi();
  final FlavorApi _flavorApi = FlavorApi();
  final TypeApi _typeApi = TypeApi();
  final TeaApi _teaApi = TeaApi();

  Future<List<TeaModel>> fetchFullTeas(Ref ref) async {
    try {
      AppLogger.debug('Начинаем загрузку полных данных о чае');

      // Запускаем все запросы параллельно
      final results = await Future.wait([
        _appearanceApi.getAppearances(),
        _countryApi.getCountries(),
        _flavorApi.getFlavors(),
        _typeApi.getTypes(),
        _teaApi.getTeas(),
      ]);

      AppLogger.debug('Получены все данные для формирования чая');

      // Раскладываем результаты по переменным с приведением типов
      final List<AppearanceResponse> appearances = results[0] as List<AppearanceResponse>;
      final List<CountryResponse> countries = results[1] as List<CountryResponse>;
      final List<FlavorResponse> flavors = results[2] as List<FlavorResponse>;
      final List<TypeResponse> types = results[3] as List<TypeResponse>;
      final List<TeaResponse> teaResponses = results[4] as List<TeaResponse>;

      // СОХРАНЯЕМ В СТОР для использования в AddScreen
      ref
          .read(metadataProvider.notifier)
          .update(TeaMetadata(appearances: appearances, countries: countries, flavors: flavors, types: types));

      AppLogger.debug('Метаданные сохранены в провайдер');

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
      AppLogger.error('Ошибка в TeaService', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> createTea({required CreateTeaDto dto, required VoidCallback onSuccess}) async {
    try {
      AppLogger.debug('Начинаем создание чая: ${dto.name}');
      AppLogger.debug('Количество изображений в DTO: ${dto.images.length}');

      await _teaApi.saveTea(dto);
      onSuccess();

      AppLogger.success('Чай "${dto.name}" успешно создан');
    } catch (e, stack) {
      AppLogger.error('Ошибка в TeaService при создании чая', error: e, stackTrace: stack);
      rethrow;
    }
  }
}

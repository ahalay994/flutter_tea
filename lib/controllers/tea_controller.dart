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

final teaControllerProvider = Provider((ref) => TeaController());

final teaListProvider = FutureProvider<List<TeaModel>>((ref) {
  final controller = ref.watch(teaControllerProvider);
  // Теперь типы совпадают идеально!
  return controller.fetchFullTeas(ref);
});

class TeaController {
  final AppearanceApi _appearanceApi = AppearanceApi();
  final CountryApi _countryApi = CountryApi();
  final FlavorApi _flavorApi = FlavorApi();
  final TypeApi _typeApi = TypeApi();
  final TeaApi _teaApi = TeaApi();

  Future<List<TeaModel>> fetchFullTeas(Ref ref) async {
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
      ref
          .read(metadataProvider.notifier)
          .update(TeaMetadata(appearances: appearances, countries: countries, flavors: flavors, types: types));

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

  Future<void> createTea(CreateTeaDto dto, {required VoidCallback onSuccess}) async {
    try {
      await _teaApi.saveTea(dto);

      // 2. ИНВАЛИДИРУЕМ (сбрасываем) провайдер списка
      // Это заставит главный экран (или любой виджет, который его слушает)
      // заново вызвать fetchFullTeas.
      onSuccess();

      AppLogger.success('Чай "${dto.name}" успешно сохранен');
    } catch (e, stack) {
      AppLogger.error('Ошибка в TeaController при создании чая', error: e, stackTrace: stack);
      rethrow; // Это гарантирует, что в AddScreen сработает блок catch и покажется модалка
    }

    AppLogger.success('Чай "${dto.name}" успешно создан');
  }
  
  // Новый метод, который сначала создает чай, а затем получает его по ID
  Future<TeaModel> createTeaWithResponse(CreateTeaDto dto, {required VoidCallback onSuccess}) async {
    try {
      // Сохраняем чай и получаем ответ
      final teaResponses = await _teaApi.saveTea(dto);
      
      // Если сервер вернул созданный чай, используем его
      if (teaResponses.isNotEmpty) {
        // Получаем все необходимые метаданные для создания модели
        final List<AppearanceResponse> appearances = await _appearanceApi.getAppearances();
        final List<CountryResponse> countries = await _countryApi.getCountries();
        final List<FlavorResponse> flavors = await _flavorApi.getFlavors();
        final List<TypeResponse> types = await _typeApi.getTypes();
        
        // Создаем модель чая из ответа
        final newTea = TeaModel.fromResponse(
          response: teaResponses.first, // Берем первый (и скорее всего единственный) ответ
          countries: countries,
          types: types,
          appearances: appearances,
          flavors: flavors,
        );
        
        // 2. ИНВАЛИДИРУЕМ (сбрасываем) провайдер списка
        onSuccess();

        AppLogger.success('Чай "${dto.name}" успешно сохранен');
        return newTea;
      } else {
        // Если сервер не вернул созданный чай, вызываем инвалидацию и получаем все чаи
        onSuccess();
        
        // Ждем немного, чтобы список обновился
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Затем получаем список чаев и находим только что созданный
        final teas = await _teaApi.getTeas();
        
        // Находим чай по имени (предполагаем, что имя уникально для тестирования)
        final createdTea = teas.firstWhere((tea) => tea.name == dto.name, 
            orElse: () => throw Exception("Новый чай не найден в списке"));
        
        // Получаем все необходимые метаданные для создания модели
        final List<AppearanceResponse> appearances = await _appearanceApi.getAppearances();
        final List<CountryResponse> countries = await _countryApi.getCountries();
        final List<FlavorResponse> flavors = await _flavorApi.getFlavors();
        final List<TypeResponse> types = await _typeApi.getTypes();
        
        final newTea = TeaModel.fromResponse(
          response: createdTea,
          countries: countries,
          types: types,
          appearances: appearances,
          flavors: flavors,
        );
        
        AppLogger.success('Чай "${dto.name}" успешно сохранен и получен');
        return newTea;
      }
    } catch (e, stack) {
      AppLogger.error('Ошибка в TeaController при создании чая', error: e, stackTrace: stack);
      rethrow; // Это гарантирует, что в AddScreen сработает блок catch и покажется модалка
    }
  }
  
  Future<bool> deleteTea(int teaId, {required VoidCallback onSuccess}) async {
    try {
      final response = await _teaApi.deleteTea(teaId);
      
      // Удалилось или нет определяем по полю ok
      if (response.ok) {
        onSuccess(); // Обновляем список
        AppLogger.success('Чай успешно удален');
        return true;
      } else {
        AppLogger.error('Ошибка при удалении чая', error: response.message);
        return false;
      }
    } catch (e, stack) {
      AppLogger.error('Ошибка в TeaController при удалении чая', error: e, stackTrace: stack);
      rethrow;
    }
  }
  
  // Метод для получения чая по ID
  Future<TeaResponse> getTea(int teaId) async {
    try {
      final response = await _teaApi.getTea(teaId);
      return response;
    } catch (e, stack) {
      AppLogger.error('Ошибка в TeaController при получении чая', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
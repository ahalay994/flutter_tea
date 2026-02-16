import 'package:flutter_test/flutter_test.dart';
import 'package:tea/api/responses/country_response.dart';
import 'package:tea/api/responses/type_response.dart';
import 'package:tea/api/responses/appearance_response.dart';
import 'package:tea/api/responses/flavor_response.dart';
import 'package:tea/models/tea.dart';

void main() {
  group('Tea Model Filter Tests', () {
    test('TeaModel.fromLocalDB should properly map IDs to names', () {
      // Создаем тестовые метаданные
      final countries = [
        CountryResponse(id: 1, name: 'Китай', createdAt: DateTime.now().toIso8601String(), updatedAt: DateTime.now().toIso8601String()),
        CountryResponse(id: 2, name: 'Индия', createdAt: DateTime.now().toIso8601String(), updatedAt: DateTime.now().toIso8601String()),
      ];
      
      final types = [
        TypeResponse(id: 1, name: 'Зелёный', createdAt: DateTime.now().toIso8601String(), updatedAt: DateTime.now().toIso8601String()),
        TypeResponse(id: 2, name: 'Чёрный', createdAt: DateTime.now().toIso8601String(), updatedAt: DateTime.now().toIso8601String()),
      ];
      
      final appearances = [
        AppearanceResponse(id: 1, name: 'Листовой', createdAt: DateTime.now().toIso8601String(), updatedAt: DateTime.now().toIso8601String()),
        AppearanceResponse(id: 2, name: 'Пакетированный', createdAt: DateTime.now().toIso8601String(), updatedAt: DateTime.now().toIso8601String()),
      ];
      
      final flavors = [
        FlavorResponse(id: 1, name: 'Цитрус', createdAt: DateTime.now().toIso8601String(), updatedAt: DateTime.now().toIso8601String()),
        FlavorResponse(id: 2, name: 'Мята', createdAt: DateTime.now().toIso8601String(), updatedAt: DateTime.now().toIso8601String()),
      ];
      
      // Создаем тестовый TeaModel из локальной базы
      final tea = TeaModel.fromLocalDB(
        id: 1,
        name: 'Тестовый чай',
        countryId: '1',
        typeId: '2',
        appearanceId: '1',
        temperature: '80',
        brewingGuide: 'Заваривать 3 минуты',
        weight: '50',
        description: 'Тестовое описание',
        flavorIds: ['1', '2'],
        images: ['https://example.com/image.jpg'],
        countries: countries,
        types: types,
        appearances: appearances,
        flavors: flavors,
      );
      
      // Проверяем, что ID были правильно преобразованы в названия
      expect(tea.country, 'Китай');
      expect(tea.type, 'Чёрный');
      expect(tea.appearance, 'Листовой');
      expect(tea.flavors, ['Цитрус', 'Мята']);
    });
  });
}
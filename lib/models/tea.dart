import 'package:tea/api/responses/appearance_response.dart';
import 'package:tea/api/responses/country_response.dart';
import 'package:tea/api/responses/flavor_response.dart';
import 'package:tea/api/responses/tea_response.dart';
import 'package:tea/api/responses/type_response.dart';
import 'package:tea/helpers/data_mapper.dart';

class TeaModel {
  final int id;
  final String name;
  final String? country;
  final String? type;
  final String? appearance;
  final String? temperature;
  final String? brewingGuide;
  final String? weight;
  final String? description;
  final List<String> flavors;
  final List<String> images;

  TeaModel({
    required this.id,
    required this.name,
    this.country,
    this.type,
    this.appearance,
    this.temperature,
    this.brewingGuide,
    this.weight,
    this.description,
    required this.flavors,
    required this.images,
  });

  // Метод для создания модели из API-ответа с заполнением названий для отображения
  static TeaModel fromResponse({
    required TeaResponse response,
    required List<CountryResponse> countries,
    required List<TypeResponse> types,
    required List<AppearanceResponse> appearances,
    required List<FlavorResponse> flavors,
  }) {
    List<String> imageUrls = DataMapper.getFieldList(response.images, (img) => img.url);
    if (imageUrls.isEmpty) {
      imageUrls = ['assets/images/default.png'];
    }

    // Заполняем названия на основе ID и метаданных
    String? countryName = response.countryId != null 
        ? DataMapper.getFieldById(countries, (c) => c.name, response.countryId) 
        : null;
    String? typeName = response.typeId != null 
        ? DataMapper.getFieldById(types, (t) => t.name, response.typeId) 
        : null;
    String? appearanceName = response.appearanceId != null 
        ? DataMapper.getFieldById(appearances, (a) => a.name, response.appearanceId) 
        : null;
    List<String> flavorNames = response.flavors.isNotEmpty 
        ? DataMapper.getFieldsByIds(flavors, (f) => f.name, response.flavors) 
        : [];

    return TeaModel(
      id: response.id,
      name: response.name,
      temperature: response.temperature,
      brewingGuide: response.brewingGuide,
      weight: response.weight,
      description: response.description,
      images: imageUrls,
      // Сохраняем названия для отображения в онлайн-режиме
      country: countryName,
      type: typeName,
      appearance: appearanceName,
      flavors: flavorNames,
    );
  }

  // Метод для создания модели из API-ответа с сохранением ID для локальной базы
  static TeaModel fromApiResponseForDatabase({
    required TeaResponse response,
  }) {
    List<String> imageUrls = DataMapper.getFieldList(response.images, (img) => img.url);
    if (imageUrls.isEmpty) {
      imageUrls = ['assets/images/default.png'];
    }

    return TeaModel(
      id: response.id,
      name: response.name,
      temperature: response.temperature,
      brewingGuide: response.brewingGuide,
      weight: response.weight,
      description: response.description,
      images: imageUrls,
      // Сохраняем ID как строки для локальной базы
      country: response.countryId?.toString(),
      type: response.typeId?.toString(),
      appearance: response.appearanceId?.toString(),
      flavors: response.flavors.map((id) => id.toString()).toList(),
    );
  }

  // Метод для создания модели из локальной БД с заполнением названий из метаданных
  static TeaModel fromLocalDB({
    required int id,
    required String name,
    String? countryId,
    String? typeId,
    String? appearanceId,
    String? temperature,
    String? brewingGuide,
    String? weight,
    String? description,
    required List<String> flavorIds,
    required List<String> images,
    required List<CountryResponse> countries,
    required List<TypeResponse> types,
    required List<AppearanceResponse> appearances,
    required List<FlavorResponse> flavors,
  }) {
    // Функция для получения названия по ID с fallback к ID в виде текста при отсутствии метаданных
    String? getNameById(List<dynamic> list, int? id, String Function(dynamic) nameExtractor, String? idText) {
      if (id == null || idText == null) return null;
      // Проверяем, есть ли метаданные (список не пуст)
      if (list.isNotEmpty) {
        return DataMapper.getFieldById(list, nameExtractor, id);
      } else {
        // Если метаданные отсутствуют, возвращаем ID как текст
        return idText;
      }
    }

    return TeaModel(
      id: id,
      name: name,
      temperature: temperature,
      brewingGuide: brewingGuide,
      weight: weight,
      description: description,
      images: images,
      country: countryId != null ? getNameById(countries, int.tryParse(countryId), (c) => c.name, countryId) : null,
      type: typeId != null ? getNameById(types, int.tryParse(typeId), (t) => t.name, typeId) : null,
      appearance: appearanceId != null ? getNameById(appearances, int.tryParse(appearanceId), (a) => a.name, appearanceId) : null,
      flavors: flavorIds.isNotEmpty 
          ? (flavors.isNotEmpty
              ? DataMapper.getFieldsByIds(flavors, (f) => f.name, flavorIds.map((id) => int.tryParse(id)).where((id) => id != null).cast<int>().toList())
              : flavorIds), // Если метаданные отсутствуют, возвращаем ID как текст
    );
  }

  // Метод для создания копии модели с изменёнными полями
  TeaModel copyWith({
    int? id,
    String? name,
    String? country,
    String? type,
    String? appearance,
    String? temperature,
    String? brewingGuide,
    String? weight,
    String? description,
    List<String>? flavors,
    List<String>? images,
  }) {
    return TeaModel(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      type: type ?? this.type,
      appearance: appearance ?? this.appearance,
      temperature: temperature ?? this.temperature,
      brewingGuide: brewingGuide ?? this.brewingGuide,
      weight: weight ?? this.weight,
      description: description ?? this.description,
      flavors: flavors ?? this.flavors,
      images: images ?? this.images,
    );
  }
}

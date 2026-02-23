import 'package:tea_multitenant/api/responses/appearance_response.dart';
import 'package:tea_multitenant/api/responses/country_response.dart';
import 'package:tea_multitenant/api/responses/flavor_response.dart';
import 'package:tea_multitenant/api/responses/tea_response.dart';
import 'package:tea_multitenant/api/responses/type_response.dart';
import 'package:tea_multitenant/helpers/data_mapper.dart';

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
    String? countryName;
    if (countryId != null) {
      int? parsedId = int.tryParse(countryId);
      if (parsedId != null && countries.isNotEmpty) {
        countryName = DataMapper.getFieldById(countries, (c) => c.name, parsedId);
      } else {
        countryName = countryId; // Если метаданные отсутствуют, используем ID как текст
      }
    }

    String? typeName;
    if (typeId != null) {
      int? parsedId = int.tryParse(typeId);
      if (parsedId != null && types.isNotEmpty) {
        typeName = DataMapper.getFieldById(types, (t) => t.name, parsedId);
      } else {
        typeName = typeId; // Если метаданные отсутствуют, используем ID как текст
      }
    }

    String? appearanceName;
    if (appearanceId != null) {
      int? parsedId = int.tryParse(appearanceId);
      if (parsedId != null && appearances.isNotEmpty) {
        appearanceName = DataMapper.getFieldById(appearances, (a) => a.name, parsedId);
      } else {
        appearanceName = appearanceId; // Если метаданные отсутствуют, используем ID как текст
      }
    }

    List<String> flavorNames;
    if (flavorIds.isNotEmpty) {
      if (flavors.isNotEmpty) {
        flavorNames = DataMapper.getFieldsByIds(flavors, (f) => f.name, 
            flavorIds.map((id) => int.tryParse(id)).where((id) => id != null).cast<int>().toList());
      } else {
        flavorNames = flavorIds; // Если метаданные отсутствуют, используем ID как текст
      }
    } else {
      flavorNames = [];
    }

    return TeaModel(
      id: id,
      name: name,
      temperature: temperature,
      brewingGuide: brewingGuide,
      weight: weight,
      description: description,
      images: images,
      country: countryName,
      type: typeName,
      appearance: appearanceName,
      flavors: flavorNames,
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

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
  
      return TeaModel(
        id: response.id,
        name: response.name,
        temperature: response.temperature,
        brewingGuide: response.brewingGuide,
        weight: response.weight,
        description: response.description,
        images: imageUrls,
        country: DataMapper.getFieldById(countries, (c) => c.name, response.countryId),
        type: DataMapper.getFieldById(types, (t) => t.name, response.typeId),
        appearance: DataMapper.getFieldById(appearances, (a) => a.name, response.appearanceId),
        flavors: DataMapper.getFieldsByIds(flavors, (f) => f.name, response.flavors),
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
    }}

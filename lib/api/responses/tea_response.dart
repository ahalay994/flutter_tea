import 'package:tea/models/image.dart';
import 'package:tea/utils/json_utils.dart';

class TeaResponse {
  final int id;
  final String name;
  final int? countryId;
  final int? typeId;
  final int? appearanceId;
  final String? temperature;
  final String? brewingGuide;
  final String? weight;
  final String? description;
  final String createdAt;
  final String updatedAt;
  final List<int> flavors;
  final List<ImageModel> images;

  TeaResponse({
    required this.id,
    required this.name,
    this.countryId,
    this.typeId,
    this.appearanceId,
    this.temperature,
    this.brewingGuide,
    this.weight,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.flavors,
    required this.images,
  });

  factory TeaResponse.fromJson(Map<String, dynamic> json) {
    return TeaResponse(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      countryId: json['countryId'] ?? json['country_id'],
      typeId: json['typeId'] ?? json['type_id'],
      appearanceId: json['appearanceId'] ?? json['appearance_id'],
      temperature: json['temperature'],
      brewingGuide: json['brewingGuide'] ?? json['brewing_guide'],
      weight: json['weight'],
      description: json['description'],
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      flavors: JsonUtils.parseList<int>(json['Flavors'] ?? json['flavors'], (item) => item as int),
      images: JsonUtils.parseList<ImageModel>(json['Images'] ?? json['images'], (item) => ImageModel.fromJson(item)),
    );
  }
}

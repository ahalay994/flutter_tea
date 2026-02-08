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
      id: json['id'],
      name: json['name'],
      countryId: json['countryId'],
      typeId: json['typeId'],
      appearanceId: json['appearanceId'],
      temperature: json['temperature'],
      brewingGuide: json['brewingGuide'],
      weight: json['weight'],
      description: json['description'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      flavors: JsonUtils.parseList<int>(json['Flavors'], (item) => item as int),
      images: JsonUtils.parseList<ImageModel>(json['Images'], (item) => ImageModel.fromJson(item)),
    );
  }
}

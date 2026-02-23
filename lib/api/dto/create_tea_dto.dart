import 'package:tea_multitenant/api/responses/image_response.dart';

class CreateTeaDto {
  final String name;
  final List<ImageResponse> images;
  final dynamic countryId; // int или String
  final dynamic typeId; // int или String
  final dynamic appearanceId; // int или String
  final List<dynamic> flavors; // List из int и String
  final String? temperature;
  final String? weight;
  final String? brewingGuide;
  final String? description;

  CreateTeaDto({
    required this.name,
    required this.images,
    this.countryId,
    this.typeId,
    this.appearanceId,
    required this.flavors,
    this.temperature,
    this.weight,
    this.brewingGuide,
    this.description,
  });

  Map<String, dynamic> toJson() => {
    "name": name,
    "countryId": countryId,
    "typeId": typeId,
    "appearanceId": appearanceId,
    "temperature": temperature ?? '',
    "weight": weight ?? '',
    "brewingGuide": brewingGuide ?? '',
    "description": description ?? '',
    "Flavors": flavors,
    "Images": images.map((img) => img.toJson()).toList(),
  };
}

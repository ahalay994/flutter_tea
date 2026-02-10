import 'package:flutter_riverpod/legacy.dart';
import 'package:tea/api/responses/appearance_response.dart';
import 'package:tea/api/responses/country_response.dart';
import 'package:tea/api/responses/flavor_response.dart';
import 'package:tea/api/responses/type_response.dart';

// Класс-хранилище всех справочников
class TeaMetadata {
  final List<AppearanceResponse> appearances;
  final List<CountryResponse> countries;
  final List<FlavorResponse> flavors;
  final List<TypeResponse> types;

  TeaMetadata({this.appearances = const [], this.countries = const [], this.flavors = const [], this.types = const []});
}

// Глобальный провайдер
final metadataProvider = StateProvider<TeaMetadata>((ref) => TeaMetadata());

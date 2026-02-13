import 'package:flutter_riverpod/flutter_riverpod.dart';
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
class MetadataNotifier extends Notifier<TeaMetadata> {
  @override
  TeaMetadata build() => TeaMetadata();

  // Метод для обновления (вместо .state = ...)
  void update(TeaMetadata newData) {
    state = newData;
  }
}

final metadataProvider = NotifierProvider<MetadataNotifier, TeaMetadata>(() {
  return MetadataNotifier();
});

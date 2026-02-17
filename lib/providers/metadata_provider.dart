import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tea/api/responses/appearance_response.dart';
import 'package:tea/api/responses/country_response.dart';
import 'package:tea/api/responses/flavor_response.dart';
import 'package:tea/api/responses/type_response.dart';
import 'package:tea/controllers/tea_controller.dart';

// Класс-хранилище всех справочников
class TeaMetadata {
  final List<AppearanceResponse> appearances;
  final List<CountryResponse> countries;
  final List<FlavorResponse> flavors;
  final List<TypeResponse> types;

  TeaMetadata({this.appearances = const [], this.countries = const [], this.flavors = const [], this.types = const []});
}

// Асинхронный провайдер для метаданных
final metadataProvider = FutureProvider<TeaMetadata>((ref) async {
  final controller = ref.read(teaControllerProvider);
  try {
    final metadata = await controller.getMetadata();
    return TeaMetadata(
      countries: metadata['countries'] as List<CountryResponse>,
      types: metadata['types'] as List<TypeResponse>,
      appearances: metadata['appearances'] as List<AppearanceResponse>,
      flavors: metadata['flavors'] as List<FlavorResponse>,
    );
  } catch (e) {
    // Возвращаем пустые списки в случае ошибки
    return TeaMetadata();
  }
});
import 'package:tea/utils/app_logger.dart';

class JsonUtils {
  /// Универсальный метод для парсинга списков любого типа.
  /// [json] - сырые данные из Map.
  /// [mapper] - функция преобразования каждого элемента (например, ImageModel.fromJson).
  static List<T> parseList<T>(dynamic json, T Function(dynamic) mapper) {
    // Если данных нет или это не список, возвращаем пустой типизированный список
    if (json == null || json is! List) {
      return <T>[];
    }

    return json
        .map((item) {
          try {
            return mapper(item);
          } catch (e) {
            // Если один элемент битый, логируем и возвращаем null, который потом отфильтруем
            AppLogger.error('Ошибка при парсинге элемента списка', error: e);
            return null;
          }
        })
        .whereType<T>() // Оставляет только успешно распарсенные элементы типа T
        .toList();
  }
}

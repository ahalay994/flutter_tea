class DataMapper {
  // 1. Получение объекта по ID
  static T? getById<T>(List<T> list, int? id) {
    if (id == null) return null;
    try {
      // Используем динамическое обращение к .id
      return list.firstWhere((item) => (item as dynamic).id == id);
    } catch (_) {
      return null;
    }
  }

  // 2. Получение name по ID
  static String? getFieldById<T>(List<T> list, String Function(T) selector, int? id, {String? fallback}) {
    final item = getById(list, id);
    return item != null ? selector(item) : fallback;
  }

  // 3. Получение списка объектов по списку ID
  static List<T> getListByIds<T>(List<T> list, List<int> ids) {
    if (ids.isEmpty) return [];
    return list.where((item) => ids.contains((item as dynamic).id)).toList();
  }

  // 4. Получение списка имен по списку ID
  static List<String> getFieldsByIds<T>(List<T> list, String Function(T) selector, List<int> ids) {
    return getListByIds(list, ids).map((item) => selector(item)).toList();
  }

  static List<String> getFieldList<T>(List<T> list, String Function(T) selector) {
    if (list.isEmpty) return [];
    return list.map((item) => selector(item)).toList();
  }
}

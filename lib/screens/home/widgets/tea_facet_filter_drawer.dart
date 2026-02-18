import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tea/api/responses/facet_response.dart';
import 'package:tea/controllers/tea_controller.dart';
import 'package:tea/utils/app_logger.dart';

class TeaFacetFilterDrawer extends ConsumerStatefulWidget {
  const TeaFacetFilterDrawer({super.key});

  @override
  ConsumerState<TeaFacetFilterDrawer> createState() => _TeaFacetFilterDrawerState();
}

class _TeaFacetFilterDrawerState extends ConsumerState<TeaFacetFilterDrawer> {
  // Параметры фильтрации
  final TextEditingController _searchController = TextEditingController();
  List<int> _selectedCountries = [];
  List<int> _selectedTypes = [];
  List<int> _selectedAppearances = [];
  List<int> _selectedFlavors = [];

  // Поля поиска внутри фильтров
  String _countrySearchQuery = '';
  String _typeSearchQuery = '';
  String _appearanceSearchQuery = '';
  String _flavorSearchQuery = '';

  // Состояния ExpansionTile
  bool _countriesExpanded = false;
  bool _typesExpanded = false;
  bool _appearancesExpanded = false;
  bool _flavorsExpanded = false;

  // Данные фасетов
  FacetResponse? _facets;

  @override
  void initState() {
    super.initState();
    // Инициализируем списки
    _selectedCountries = [];
    _selectedTypes = [];
    _selectedAppearances = [];
    _selectedFlavors = [];

    // Обновляем локальное состояние при инициализации
    _updateLocalStateFromProvider();

    // Загружаем фасеты
    _loadFacets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Метод для загрузки фасетов
  Future<void> _loadFacets() async {
    try {
      // Получаем текущие параметры фильтрации
      final filterParams = <String, dynamic>{};

      if (_searchController.text.isNotEmpty) {
        filterParams['search'] = _searchController.text;
      }

      if (_selectedCountries.isNotEmpty) {
        filterParams['countries'] = _selectedCountries.join(',');
      }

      if (_selectedTypes.isNotEmpty) {
        filterParams['types'] = _selectedTypes.join(',');
      }

      if (_selectedAppearances.isNotEmpty) {
        filterParams['appearances'] = _selectedAppearances.join(',');
      }

      if (_selectedFlavors.isNotEmpty) {
        filterParams['flavors'] = _selectedFlavors.join(',');
      }

      final teaController = ref.read(teaControllerProvider);
      final facets = await teaController.getFacets(filterParams);

      if (mounted) {
        setState(() {
          _facets = facets;
        });
      }
    } catch (e) {
      AppLogger.error('Ошибка при загрузке фасетов', error: e);
    }
  }

  // Метод для обновления локального состояния из провайдера фильтров
  void _updateLocalStateFromProvider() {
    final filterParams = ref.read(filterParamsProvider);

    // Обновляем локальное состояние на основе параметров фильтрации из провайдера
    if (filterParams.containsKey('search')) {
      _searchController.text = filterParams['search'] ?? '';
    } else {
      _searchController.clear();
    }

    if (filterParams.containsKey('countries')) {
      final countriesStr = filterParams['countries'] as String;
      _selectedCountries = countriesStr
          .split(',')
          .map((e) => int.tryParse(e))
          .where((e) => e != null)
          .cast<int>()
          .toList();
    } else {
      _selectedCountries.clear();
    }

    if (filterParams.containsKey('types')) {
      final typesStr = filterParams['types'] as String;
      _selectedTypes = typesStr.split(',').map((e) => int.tryParse(e)).where((e) => e != null).cast<int>().toList();
    } else {
      _selectedTypes.clear();
    }

    if (filterParams.containsKey('appearances')) {
      final appearancesStr = filterParams['appearances'] as String;
      _selectedAppearances = appearancesStr
          .split(',')
          .map((e) => int.tryParse(e))
          .where((e) => e != null)
          .cast<int>()
          .toList();
    } else {
      _selectedAppearances.clear();
    }

    if (filterParams.containsKey('flavors')) {
      final flavorsStr = filterParams['flavors'] as String;
      _selectedFlavors = flavorsStr.split(',').map((e) => int.tryParse(e)).where((e) => e != null).cast<int>().toList();
    } else {
      _selectedFlavors.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Подписываемся на изменения провайдера фильтров и обновляем локальное состояние
    ref.listen(filterParamsProvider, (previous, next) {
      if (previous != next) {
        if (mounted) {
          setState(() {
            _updateLocalStateFromProvider();
          });
          // Перезагружаем фасеты
          _loadFacets();
        }
      }
    });

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).colorScheme.secondaryContainer,
                ],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40),
                Text(
                  'Фильтры',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Выбор с отображением количества', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Поле поиска
                    const Text('Поиск', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Поиск по названию, описанию...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _loadFacets(); // Перезагружаем фасеты при изменении поиска
                      },
                    ),
                    const SizedBox(height: 20),

                    // Фильтр по странам
                    if (_facets != null)
                      if (_facets!.countries.isNotEmpty)
                        Column(
                          children: [
                            ExpansionTile(
                              title: Text('Страны', style: TextStyle(fontWeight: FontWeight.w600)),
                              initiallyExpanded: _countriesExpanded,
                              onExpansionChanged: (expanded) {
                                setState(() {
                                  _countriesExpanded = expanded;
                                });
                              },
                              children: [
                                _buildFacetList(
                                  _facets!.countries,
                                  _selectedCountries,
                                  (id) => _toggleCountry(id),
                                  _countrySearchQuery,
                                  (query) => setState(() => _countrySearchQuery = query),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                        )
                      else
                        const SizedBox.shrink()
                    else
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),

                    // Фильтр по типам
                    if (_facets != null)
                      if (_facets!.types.isNotEmpty)
                        Column(
                          children: [
                            ExpansionTile(
                              title: Text('Типы', style: TextStyle(fontWeight: FontWeight.w600)),
                              initiallyExpanded: _typesExpanded,
                              onExpansionChanged: (expanded) {
                                setState(() {
                                  _typesExpanded = expanded;
                                });
                              },
                              children: [
                                _buildFacetList(
                                  _facets!.types,
                                  _selectedTypes,
                                  (id) => _toggleType(id),
                                  _typeSearchQuery,
                                  (query) => setState(() => _typeSearchQuery = query),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                        )
                      else
                        const SizedBox.shrink()
                    else
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),

                    // Фильтр по внешнему виду
                    if (_facets != null)
                      if (_facets!.appearances.isNotEmpty)
                        Column(
                          children: [
                            ExpansionTile(
                              title: Text('Внешний вид', style: TextStyle(fontWeight: FontWeight.w600)),
                              initiallyExpanded: _appearancesExpanded,
                              onExpansionChanged: (expanded) {
                                setState(() {
                                  _appearancesExpanded = expanded;
                                });
                              },
                              children: [
                                _buildFacetList(
                                  _facets!.appearances,
                                  _selectedAppearances,
                                  (id) => _toggleAppearance(id),
                                  _appearanceSearchQuery,
                                  (query) => setState(() => _appearanceSearchQuery = query),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                        )
                      else
                        const SizedBox.shrink()
                    else
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),

                    // Фильтр по вкусам
                    if (_facets != null)
                      if (_facets!.flavors.isNotEmpty)
                        Column(
                          children: [
                            ExpansionTile(
                              title: Text('Вкусы', style: TextStyle(fontWeight: FontWeight.w600)),
                              initiallyExpanded: _flavorsExpanded,
                              onExpansionChanged: (expanded) {
                                setState(() {
                                  _flavorsExpanded = expanded;
                                });
                              },
                              children: [
                                _buildFacetList(
                                  _facets!.flavors,
                                  _selectedFlavors,
                                  (id) => _toggleFlavor(id),
                                  _flavorSearchQuery,
                                  (query) => setState(() => _flavorSearchQuery = query),
                                ),
                              ],
                            ),
                          ],
                        )
                      else
                        const SizedBox.shrink()
                    else
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Кнопки управления фильтрами
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Применить фильтры', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 10),
                Consumer(
                  builder: (context, ref, child) {
                    final filterParams = ref.watch(filterParamsProvider);
                    final hasActiveFilters =
                        filterParams.isNotEmpty &&
                        (filterParams['search']?.toString().isNotEmpty == true ||
                            filterParams['countries']?.toString().isNotEmpty == true ||
                            filterParams['types']?.toString().isNotEmpty == true ||
                            filterParams['appearances']?.toString().isNotEmpty == true ||
                            filterParams['flavors']?.toString().isNotEmpty == true);

                    return hasActiveFilters
                        ? SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _resetFilters,
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                              child: const Text(
                                'Сбросить фильтры',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          )
                        : const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Вспомогательный метод для построения списка фасетов
  Widget _buildFacetList(
    List<FacetItem> items,
    List<int> selectedItems,
    Function(int id) onToggle,
    String searchQuery,
    Function(String query) onSearchChanged,
  ) {
    // Фильтруем элементы только по поисковому запросу, но не скрываем элементы с count = 0
    final filteredItems = items.where((item) {
      return searchQuery.isEmpty || item.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Поиск...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: onSearchChanged,
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Позволяет встроить ListView в ExpansionTile
          itemCount: filteredItems.length,
          itemBuilder: (context, index) {
            final item = filteredItems[index];
            final isSelected = selectedItems.contains(item.id);

            return CheckboxListTile(
              title: Row(
                children: [
                  Expanded(child: Text(item.name)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? Theme.of(context).primaryColor.withOpacity(0.1) 
                        : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.count.toString(),
                      style: TextStyle(
                        color: isSelected 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey, 
                        fontSize: 12
                      ),
                    ),
                  ),
                ],
              ),
              value: isSelected,
              onChanged: (bool? value) {
                onToggle(item.id);
                // Не перезагружаем фасеты при изменении чекбокса, только обновляем локальное состояние
              },
            );
          },
        ),
      ],
    );
  }

  void _toggleCountry(int id) {
    setState(() {
      if (_selectedCountries.contains(id)) {
        _selectedCountries.remove(id);
        AppLogger.debug('Удалена страна: $id');
      } else {
        _selectedCountries.add(id);
        AppLogger.debug('Добавлена страна: $id');
      }
    });
  }

  void _toggleType(int id) {
    setState(() {
      if (_selectedTypes.contains(id)) {
        _selectedTypes.remove(id);
        AppLogger.debug('Удален тип: $id');
      } else {
        _selectedTypes.add(id);
        AppLogger.debug('Добавлен тип: $id');
      }
    });
  }

  void _toggleAppearance(int id) {
    setState(() {
      if (_selectedAppearances.contains(id)) {
        _selectedAppearances.remove(id);
        AppLogger.debug('Удален внешний вид: $id');
      } else {
        _selectedAppearances.add(id);
        AppLogger.debug('Добавлен внешний вид: $id');
      }
    });
  }

  void _toggleFlavor(int id) {
    setState(() {
      if (_selectedFlavors.contains(id)) {
        _selectedFlavors.remove(id);
        AppLogger.debug('Удален вкус: $id');
      } else {
        _selectedFlavors.add(id);
        AppLogger.debug('Добавлен вкус: $id');
      }
    });
  }

  void _applyFilters() {
    AppLogger.debug('Нажата кнопка "Применить фильтры"');

    // Формируем параметры фильтрации
    final filterParams = <String, dynamic>{};

    if (_searchController.text.isNotEmpty) {
      filterParams['search'] = _searchController.text;
      AppLogger.debug('Добавлен фильтр поиска: ${_searchController.text}');
    }

    if (_selectedCountries.isNotEmpty) {
      filterParams['countries'] = _selectedCountries.join(',');
      AppLogger.debug('Добавлены фильтры стран: ${_selectedCountries.join(',')} (${_selectedCountries.length} шт.)');
    }

    if (_selectedTypes.isNotEmpty) {
      filterParams['types'] = _selectedTypes.join(',');
      AppLogger.debug('Добавлены фильтры типов: ${_selectedTypes.join(',')} (${_selectedTypes.length} шт.)');
    }

    if (_selectedAppearances.isNotEmpty) {
      filterParams['appearances'] = _selectedAppearances.join(',');
      AppLogger.debug(
        'Добавлены фильтры внешних видов: ${_selectedAppearances.join(',')} (${_selectedAppearances.length} шт.)',
      );
    }

    if (_selectedFlavors.isNotEmpty) {
      filterParams['flavors'] = _selectedFlavors.join(',');
      AppLogger.debug('Добавлены фильтры вкусов: ${_selectedFlavors.join(',')} (${_selectedFlavors.length} шт.)');
    }

    AppLogger.debug('Параметры фильтрации до обновления: $filterParams');

    // Обновляем провайдер параметров фильтрации
    ref.read(filterParamsProvider.notifier).update(filterParams);
    AppLogger.debug('Провайдер фильтров обновлен с параметрами: $filterParams');

    // Закрываем drawer
    Navigator.of(context).pop();
    AppLogger.debug('Drawer закрыт после применения фильтров');
  }

  void _resetFilters() {
    AppLogger.debug('Нажата кнопка "Сбросить фильтры"');

    // Очищаем все параметры фильтрации
    setState(() {
      AppLogger.debug('Очищаем контроллер поиска: ${_searchController.text}');
      _searchController.clear();
      AppLogger.debug('Очищаем список стран: ${_selectedCountries.length} шт.');
      _selectedCountries.clear();
      AppLogger.debug('Очищаем список типов: ${_selectedTypes.length} шт.');
      _selectedTypes.clear();
      AppLogger.debug('Очищаем список внешних видов: ${_selectedAppearances.length} шт.');
      _selectedAppearances.clear();
      AppLogger.debug('Очищаем список вкусов: ${_selectedFlavors.length} шт.');
      _selectedFlavors.clear();

      // Также очищаем строки поиска внутри фильтров
      _countrySearchQuery = '';
      _typeSearchQuery = '';
      _appearanceSearchQuery = '';
      _flavorSearchQuery = '';
    });

    // Сбрасываем параметры фильтрации в провайдере
    ref.read(filterParamsProvider.notifier).clear();
    AppLogger.debug('Провайдер фильтров сброшен');

    // Загружаем фасеты без фильтров
    _loadFacets();

    // Закрываем drawer
    Navigator.of(context).pop();
    AppLogger.debug('Drawer закрыт после сброса фильтров');
  }
}

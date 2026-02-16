import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tea/controllers/tea_controller.dart';
import 'package:tea/utils/app_logger.dart';
import 'filter_widgets.dart';

class TeaFilterDrawer extends ConsumerStatefulWidget {
  const TeaFilterDrawer({super.key});

  @override
  ConsumerState<TeaFilterDrawer> createState() => _TeaFilterDrawerState();
}

class _TeaFilterDrawerState extends ConsumerState<TeaFilterDrawer> {
  // Параметры фильтрации
  final TextEditingController _searchController = TextEditingController();
  late List<int> _selectedCountries;
  late List<int> _selectedTypes;
  late List<int> _selectedAppearances;
  late List<int> _selectedFlavors;

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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      _selectedCountries = countriesStr.split(',').map((e) => int.tryParse(e)).where((e) => e != null).cast<int>().toList();
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
      _selectedAppearances = appearancesStr.split(',').map((e) => int.tryParse(e)).where((e) => e != null).cast<int>().toList();
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
        }
      }
    });

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Colors.blue,
              // ignore: deprecated_member_use
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue, Colors.blueAccent],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40),
                Text(
                  'Фильтры',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Поиск и фильтрация чаёв',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
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
                    const Text(
                      'Поиск',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Поиск по названию, описанию...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Фильтр по странам
                    ExpansionTile(
                      title: const Text(
                        'Страны',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      initiallyExpanded: _countriesExpanded,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _countriesExpanded = expanded;
                        });
                      },
                      children: [
                        CountryFilterWidget(
                          selectedCountries: _selectedCountries,
                          onSelectionChanged: (newSelection) {
                            setState(() {
                              _selectedCountries = newSelection;
                            });
                          },
                          searchQuery: _countrySearchQuery,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Фильтр по типам
                    ExpansionTile(
                      title: const Text(
                        'Типы',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      initiallyExpanded: _typesExpanded,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _typesExpanded = expanded;
                        });
                      },
                      children: [
                        TypeFilterWidget(
                          selectedTypes: _selectedTypes,
                          onSelectionChanged: (newSelection) {
                            setState(() {
                              _selectedTypes = newSelection;
                            });
                          },
                          searchQuery: _typeSearchQuery,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Фильтр по внешнему виду
                    ExpansionTile(
                      title: const Text(
                        'Внешний вид',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      initiallyExpanded: _appearancesExpanded,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _appearancesExpanded = expanded;
                        });
                      },
                      children: [
                        AppearanceFilterWidget(
                          selectedAppearances: _selectedAppearances,
                          onSelectionChanged: (newSelection) {
                            setState(() {
                              _selectedAppearances = newSelection;
                            });
                          },
                          searchQuery: _appearanceSearchQuery,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Фильтр по вкусам
                    ExpansionTile(
                      title: const Text(
                        'Вкусы',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      initiallyExpanded: _flavorsExpanded,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _flavorsExpanded = expanded;
                        });
                      },
                      children: [
                        FlavorFilterWidget(
                          selectedFlavors: _selectedFlavors,
                          onSelectionChanged: (newSelection) {
                            setState(() {
                              _selectedFlavors = newSelection;
                            });
                          },
                          searchQuery: _flavorSearchQuery,
                        ),
                      ],
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
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Применить фильтры',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _resetFilters,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Сбросить фильтры',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
      AppLogger.debug('Добавлены фильтры внешних видов: ${_selectedAppearances.join(',')} (${_selectedAppearances.length} шт.)');
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
    
    // Закрываем drawer
    Navigator.of(context).pop();
    AppLogger.debug('Drawer закрыт после сброса фильтров');
  }
}
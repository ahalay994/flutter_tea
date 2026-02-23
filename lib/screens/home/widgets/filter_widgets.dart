import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tea_multitenant/api/responses/appearance_response.dart';
import 'package:tea_multitenant/api/responses/country_response.dart';
import 'package:tea_multitenant/api/responses/flavor_response.dart';
import 'package:tea_multitenant/api/responses/type_response.dart';
import 'package:tea_multitenant/controllers/tea_controller.dart';
import 'package:tea_multitenant/utils/app_logger.dart';

class CountryFilterWidget extends ConsumerStatefulWidget {
  final List<int> selectedCountries;
  final Function(List<int>) onSelectionChanged;
  final String searchQuery;

  const CountryFilterWidget({
    super.key,
    required this.selectedCountries,
    required this.onSelectionChanged,
    required this.searchQuery,
  });

  @override
  ConsumerState<CountryFilterWidget> createState() => _CountryFilterWidgetState();
}

class _CountryFilterWidgetState extends ConsumerState<CountryFilterWidget> {
  late final TextEditingController _searchController;
  String _currentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _currentSearchQuery = widget.searchQuery;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(CountryFilterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _currentSearchQuery = widget.searchQuery;
      _searchController.text = widget.searchQuery;
    }
  }

  void _onSearchChanged() {
    _currentSearchQuery = _searchController.text;
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teaController = ref.read(teaControllerProvider);
    
    return FutureBuilder<List<CountryResponse>>(
      future: teaController.countries,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Ошибка при загрузке стран'),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Нет доступных стран'),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Поиск стран...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            // Список стран с возможностью фильтрации
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // Позволяет встроить ListView в ExpansionTile
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final country = snapshot.data![index];
                // Проверяем, нужно ли отображать эту страну в зависимости от поиска
                final shouldShow = _currentSearchQuery.isEmpty ||
                    country.name.toLowerCase().contains(_currentSearchQuery.toLowerCase());

                if (!shouldShow) return Container(); // Не отображаем, если не подходит под фильтр

                return CheckboxListTile(
                  title: Text(country.name),
                  value: widget.selectedCountries.contains(country.id),
                  onChanged: (bool? value) {
                    final newSelectedCountries = List<int>.from(widget.selectedCountries);
                    if (value == true) {
                      newSelectedCountries.add(country.id);
                      AppLogger.debug('Добавлена страна: ${country.name} (ID: ${country.id})');
                    } else {
                      newSelectedCountries.remove(country.id);
                      AppLogger.debug('Удалена страна: ${country.name} (ID: ${country.id})');
                    }
                    AppLogger.debug('Всего выбранных стран: ${newSelectedCountries.length}');
                    widget.onSelectionChanged(newSelectedCountries);
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class TypeFilterWidget extends ConsumerStatefulWidget {
  final List<int> selectedTypes;
  final Function(List<int>) onSelectionChanged;
  final String searchQuery;

  const TypeFilterWidget({
    super.key,
    required this.selectedTypes,
    required this.onSelectionChanged,
    required this.searchQuery,
  });

  @override
  ConsumerState<TypeFilterWidget> createState() => _TypeFilterWidgetState();
}

class _TypeFilterWidgetState extends ConsumerState<TypeFilterWidget> {
  late final TextEditingController _searchController;
  String _currentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _currentSearchQuery = widget.searchQuery;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(TypeFilterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _currentSearchQuery = widget.searchQuery;
      _searchController.text = widget.searchQuery;
    }
  }

  void _onSearchChanged() {
    _currentSearchQuery = _searchController.text;
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teaController = ref.read(teaControllerProvider);
    
    return FutureBuilder<List<TypeResponse>>(
      future: teaController.types,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Ошибка при загрузке типов'),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Нет доступных типов'),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Поиск типов...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            // Список типов с возможностью фильтрации
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // Позволяет встроить ListView в ExpansionTile
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final type = snapshot.data![index];
                // Проверяем, нужно ли отображать этот тип в зависимости от поиска
                final shouldShow = _currentSearchQuery.isEmpty ||
                    type.name.toLowerCase().contains(_currentSearchQuery.toLowerCase());

                if (!shouldShow) return Container(); // Не отображаем, если не подходит под фильтр

                return CheckboxListTile(
                  title: Text(type.name),
                  value: widget.selectedTypes.contains(type.id),
                  onChanged: (bool? value) {
                    final newSelectedTypes = List<int>.from(widget.selectedTypes);
                    if (value == true) {
                      newSelectedTypes.add(type.id);
                      AppLogger.debug('Добавлен тип: ${type.name} (ID: ${type.id})');
                    } else {
                      newSelectedTypes.remove(type.id);
                      AppLogger.debug('Удален тип: ${type.name} (ID: ${type.id})');
                    }
                    AppLogger.debug('Всего выбранных типов: ${newSelectedTypes.length}');
                    widget.onSelectionChanged(newSelectedTypes);
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class AppearanceFilterWidget extends ConsumerStatefulWidget {
  final List<int> selectedAppearances;
  final Function(List<int>) onSelectionChanged;
  final String searchQuery;

  const AppearanceFilterWidget({
    super.key,
    required this.selectedAppearances,
    required this.onSelectionChanged,
    required this.searchQuery,
  });

  @override
  ConsumerState<AppearanceFilterWidget> createState() => _AppearanceFilterWidgetState();
}

class _AppearanceFilterWidgetState extends ConsumerState<AppearanceFilterWidget> {
  late final TextEditingController _searchController;
  String _currentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _currentSearchQuery = widget.searchQuery;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(AppearanceFilterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _currentSearchQuery = widget.searchQuery;
      _searchController.text = widget.searchQuery;
    }
  }

  void _onSearchChanged() {
    _currentSearchQuery = _searchController.text;
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teaController = ref.read(teaControllerProvider);
    
    return FutureBuilder<List<AppearanceResponse>>(
      future: teaController.appearances,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Ошибка при загрузке внешнего вида'),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Нет доступных внешних видов'),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Поиск внешних видов...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            // Список внешних видов с возможностью фильтрации
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // Позволяет встроить ListView в ExpansionTile
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final appearance = snapshot.data![index];
                // Проверяем, нужно ли отображать этот внешний вид в зависимости от поиска
                final shouldShow = _currentSearchQuery.isEmpty ||
                    appearance.name.toLowerCase().contains(_currentSearchQuery.toLowerCase());

                if (!shouldShow) return Container(); // Не отображаем, если не подходит под фильтр

                return CheckboxListTile(
                  title: Text(appearance.name),
                  value: widget.selectedAppearances.contains(appearance.id),
                  onChanged: (bool? value) {
                    final newSelectedAppearances = List<int>.from(widget.selectedAppearances);
                    if (value == true) {
                      newSelectedAppearances.add(appearance.id);
                      AppLogger.debug('Добавлен внешний вид: ${appearance.name} (ID: ${appearance.id})');
                    } else {
                      newSelectedAppearances.remove(appearance.id);
                      AppLogger.debug('Удален внешний вид: ${appearance.name} (ID: ${appearance.id})');
                    }
                    AppLogger.debug('Всего выбранных внешних видов: ${newSelectedAppearances.length}');
                    widget.onSelectionChanged(newSelectedAppearances);
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class FlavorFilterWidget extends ConsumerStatefulWidget {
  final List<int> selectedFlavors;
  final Function(List<int>) onSelectionChanged;
  final String searchQuery;

  const FlavorFilterWidget({
    super.key,
    required this.selectedFlavors,
    required this.onSelectionChanged,
    required this.searchQuery,
  });

  @override
  ConsumerState<FlavorFilterWidget> createState() => _FlavorFilterWidgetState();
}

class _FlavorFilterWidgetState extends ConsumerState<FlavorFilterWidget> {
  late final TextEditingController _searchController;
  String _currentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _currentSearchQuery = widget.searchQuery;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(FlavorFilterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _currentSearchQuery = widget.searchQuery;
      _searchController.text = widget.searchQuery;
    }
  }

  void _onSearchChanged() {
    _currentSearchQuery = _searchController.text;
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teaController = ref.read(teaControllerProvider);
    
    return FutureBuilder<List<FlavorResponse>>(
      future: teaController.flavors,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Ошибка при загрузке вкусов'),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Нет доступных вкусов'),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Поиск вкусов...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            // Список вкусов с возможностью фильтрации
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // Позволяет встроить ListView в ExpansionTile
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final flavor = snapshot.data![index];
                // Проверяем, нужно ли отображать этот вкус в зависимости от поиска
                final shouldShow = _currentSearchQuery.isEmpty ||
                    flavor.name.toLowerCase().contains(_currentSearchQuery.toLowerCase());

                if (!shouldShow) return Container(); // Не отображаем, если не подходит под фильтр

                return CheckboxListTile(
                  title: Text(flavor.name),
                  value: widget.selectedFlavors.contains(flavor.id),
                  onChanged: (bool? value) {
                    final newSelectedFlavors = List<int>.from(widget.selectedFlavors);
                    if (value == true) {
                      newSelectedFlavors.add(flavor.id);
                      AppLogger.debug('Добавлен вкус: ${flavor.name} (ID: ${flavor.id})');
                    } else {
                      newSelectedFlavors.remove(flavor.id);
                      AppLogger.debug('Удален вкус: ${flavor.name} (ID: ${flavor.id})');
                    }
                    AppLogger.debug('Всего выбранных вкусов: ${newSelectedFlavors.length}');
                    widget.onSelectionChanged(newSelectedFlavors);
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}
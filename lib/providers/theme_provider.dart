import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Перечисление для тем приложения
enum AppTheme {
  custom('Пользовательская', Color(0xFF9B59B6), Color(0xFFFF69B4)),
  customUpdated('Пользовательская (обновленная)', Color(0xFF9B59B6), Color(0xFFFF69B4));

  const AppTheme(this.displayName, this.primaryColor, this.secondaryColor);
  
  final String displayName;
  final Color primaryColor;
  final Color secondaryColor;
}

// Глобальный менеджер тем
class ThemeManager {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  AppTheme _currentTheme = AppTheme.custom;
  Color _customPrimaryColor = const Color(0xFF9B59B6);
  Color _customSecondaryColor = const Color(0xFFFF69B4);
  final ValueNotifier<AppTheme> _themeNotifier = ValueNotifier(AppTheme.custom);
  
  // Название ключа для сохранения темы
  static const String _themeKey = 'selected_theme';
  static const String _customPrimaryColorKey = 'custom_primary_color';
  static const String _customSecondaryColorKey = 'custom_secondary_color';
  
  AppTheme get currentTheme => _currentTheme;
  Color get customPrimaryColor => _customPrimaryColor;
  Color get customSecondaryColor => _customSecondaryColor;
  ValueNotifier<AppTheme> get themeNotifier => _themeNotifier;
  
  // Асинхронная инициализация - загружаем сохраненные цвета
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedThemeName = prefs.getString(_themeKey);
    
    // Проверяем, есть ли сохраненная тема (для совместимости)
    if (savedThemeName != null) {
      // Проверяем, является ли это кастомной темой
      if (savedThemeName.contains('custom')) {
        int? savedPrimaryColor = prefs.getInt(_customPrimaryColorKey);
        int? savedSecondaryColor = prefs.getInt(_customSecondaryColorKey);
        
        if (savedPrimaryColor != null) {
          _customPrimaryColor = Color(savedPrimaryColor);
        }
        if (savedSecondaryColor != null) {
          _customSecondaryColor = Color(savedSecondaryColor);
        }
      }
    }
    
    // Всегда устанавливаем пользовательскую тему как текущую
    _currentTheme = AppTheme.custom;
    _themeNotifier.value = AppTheme.custom;
  }
  
  void setTheme(AppTheme theme) {
    // Обновляем значение темы
    _currentTheme = theme;
    _themeNotifier.value = theme;
    
    // Сохраняем тему в SharedPreferences
    _saveTheme(theme);
  }
  
  void setCustomColors(Color primaryColor, Color secondaryColor) {
    _customPrimaryColor = primaryColor;
    _customSecondaryColor = secondaryColor;
    
    // Для обновления UI временно переключаем тему на customUpdated и обратно на custom
    _currentTheme = AppTheme.customUpdated;
    _themeNotifier.value = AppTheme.customUpdated;
    
    // Затем в следующем кадре возвращаем к пользовательской теме
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currentTheme = AppTheme.custom;
      _themeNotifier.value = AppTheme.custom;
    });
    
    // Сохраняем пользовательские цвета
    _saveCustomColors(primaryColor, secondaryColor);
  }
  
  // Приватный метод для сохранения темы
  Future<void> _saveTheme(AppTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.toString());
  }
  
  // Приватный метод для сохранения пользовательских цветов
  Future<void> _saveCustomColors(Color primaryColor, Color secondaryColor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_customPrimaryColorKey, primaryColor.value);
    await prefs.setInt(_customSecondaryColorKey, secondaryColor.value);
  }
}

// Провайдер для темы
final themeProvider = Provider<AppTheme>((ref) {
  return ThemeManager().currentTheme;
});

// Провайдер для ValueNotifier темы
final themeNotifierProvider = Provider<ValueNotifier<AppTheme>>((ref) {
  return ThemeManager().themeNotifier;
});

// Провайдер для пользовательских цветов
final customColorsProvider = Provider.autoDispose((ref) {
  final currentTheme = ref.watch(themeProvider);
  if (currentTheme == AppTheme.custom || currentTheme == AppTheme.customUpdated) {
    return (ThemeManager().customPrimaryColor, ThemeManager().customSecondaryColor);
  } else {
    return (currentTheme.primaryColor, currentTheme.secondaryColor);
  }
});
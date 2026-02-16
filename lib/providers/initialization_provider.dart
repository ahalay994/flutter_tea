import 'package:flutter_riverpod/flutter_riverpod.dart';

// Провайдер для отслеживания статуса инициализации приложения
final initializationProvider = FutureProvider<bool>((ref) async {
  // Этот провайдер позволяет отслеживать завершение инициализации
  // но не блокирует отображение UI до завершения инициализации
  return true; // Просто возвращаем true, чтобы показать, что приложение может отображаться
});
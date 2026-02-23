import 'package:flutter/material.dart';
import 'package:tea_multitenant/widgets/animated_loader.dart';

// Глобальная переменная для отслеживания активного OverlayEntry
OverlayEntry? _fullScreenLoaderEntry;

extension UiHelpers on BuildContext {
  // Универсальная модалка ошибки
  void showErrorDialog(String message) {
    showDialog(
      context: this,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text("Ошибка"),
          ],
        ),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("ОК"))],
      ),
    );
  }

  // Универсальное сообщение об успехе (Снекбар)
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
    );
  }

  // Стандартный модальный лоадер (как раньше)
  void showLoadingDialog() {
    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        backgroundColor: Colors.transparent,
        child: Center(
          child: Image(
            image: AssetImage('assets/images/loader.gif'),
            width: 100,
            height: 100,
          ),
        ),
      ),
    );
  }

  // Скрытие стандартного модального лоадера
  void hideLoading() {
    // Пытаемся закрыть любой открытый Dialog/Modal с помощью pop()
    // Используем try-catch, чтобы избежать ошибок, если ничего нечего закрывать
    try {
      Navigator.of(this).pop();
    } catch (e) {
      // Если нечего закрывать, просто игнорируем ошибку
    }
  }

  // Показ полноэкранного лоадера с использованием Overlay
  void showFullScreenLoader() {
    // Убедимся, что предыдущий лоадер закрыт
    hideFullScreenLoader();

    _fullScreenLoaderEntry = OverlayEntry(
      builder: (context) => Container(
        color: Colors.white.withValues(alpha: 0.8), // Прозрачный белый фон
        child: const Center(
          child: AnimatedLoader(size: 100),
        ),
      ),
    );

    // Добавляем OverlayEntry в Overlay
    Overlay.of(this)?.insert(_fullScreenLoaderEntry!);
  }

  // Скрытие полноэкранного лоадера
  void hideFullScreenLoader() {
    if (_fullScreenLoaderEntry != null) {
      _fullScreenLoaderEntry!.remove();
      _fullScreenLoaderEntry = null;
    }
  }
}

// Вспомогательная функция для проверки, содержит ли HTML-контент что-то кроме пустых тегов
bool isHtmlContentNotEmpty(String? html) {
  if (html == null) return false;
  
  // Удаляем HTML-теги и проверяем, есть ли текст
  String text = html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  return text.isNotEmpty;
}
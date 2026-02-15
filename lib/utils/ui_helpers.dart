import 'package:flutter/material.dart';

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

  void hideLoading() {
    if (Navigator.of(this).canPop()) {
      Navigator.of(this).pop();
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
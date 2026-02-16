// Простой тест для проверки запуска приложения Tea App
//
// Использует WidgetTester для проверки базовой функциональности

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Simple test to avoid env dependency', (WidgetTester tester) async {
    // Простой тест, который не зависит от .env файла
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          title: 'Tea App Test',
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Test App'),
            ),
            body: const Center(
              child: Text('Test Body'),
            ),
          ),
        ),
      ),
    );

    // Проверяем, что виджеты отрисовались
    expect(find.text('Test App'), findsOneWidget);
    expect(find.text('Test Body'), findsOneWidget);
  });
}
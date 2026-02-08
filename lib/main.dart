import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tea/controllers/tea_controller.dart';
import 'package:tea/utils/app_logger.dart';
import 'package:tea/widgets/tea_card.dart';

import 'models/tea.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const TeaApp());
}

final TeaController _controller = TeaController();

class TeaApp extends StatelessWidget {
  const TeaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blueGrey),
      home: const TeaListScreen(),
    );
  }
}

class TeaListScreen extends StatelessWidget {
  const TeaListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(dotenv.env['APP_NAME'] ?? '')),

      // 1. БОКОВОЕ МЕНЮ (Фильтры)
      drawer: Drawer(
        child: ListView(
          children: const [
            DrawerHeader(child: Text('Фильтры', style: TextStyle(fontSize: 24))),
            ListTile(leading: Icon(Icons.filter_list), title: Text('Только Улуны')),
          ],
        ),
      ),

      // 2. СПИСОК ЧАЕВ
      body: FutureBuilder<List<TeaModel>>(
        future: _controller.fetchFullTeas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            AppLogger.error('Ошибка в FutureBuilder', error: snapshot.error);

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    Text('Не удалось загрузить чаи', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(), // Показывает текст ошибки (например, 404 или Network Error)
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          }

          final teas = snapshot.data ?? [];
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: teas.length,
            itemBuilder: (context, index) => TeaCard(tea: teas[index]),
          );
        },
      ),

      // 3. КНОПКА ДОБАВЛЕНИЯ (FAB)
      floatingActionButton: FloatingActionButton(
        onPressed: () => print('Открыть форму добавления'),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}

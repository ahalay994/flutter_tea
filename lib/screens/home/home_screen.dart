import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tea/controllers/tea_controller.dart';
import 'package:tea/models/tea.dart';
import 'package:tea/screens/add/add_screen.dart';
import 'package:tea/utils/app_logger.dart';

import 'widgets/tea_card.dart';
import 'widgets/tea_drawer.dart';

class TeaListScreen extends ConsumerStatefulWidget {
  const TeaListScreen({super.key});

  @override
  ConsumerState<TeaListScreen> createState() => _TeaListScreenState();
}

class _TeaListScreenState extends ConsumerState<TeaListScreen> {
  final TeaController _controller = TeaController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(dotenv.env['APP_NAME'] ?? 'Tea App')),
      drawer: const TeaFilterDrawer(),
      body: FutureBuilder<List<TeaModel>>(
        future: _controller.fetchFullTeas(ref),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            AppLogger.error('Ошибка в FutureBuilder', error: snapshot.error);
            return _buildErrorWidget(snapshot.error.toString());
          }

          final teas = snapshot.data ?? [];
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: teas.length,
            itemBuilder: (context, index) => TeaCard(tea: teas[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddScreen()));
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            const Text('Не удалось загрузить чаи', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

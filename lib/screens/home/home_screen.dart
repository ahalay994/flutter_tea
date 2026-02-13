import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tea/controllers/tea_controller.dart';
import 'package:tea/screens/add/add_screen.dart';
import 'package:tea/utils/ui_helpers.dart';

import 'widgets/tea_card.dart';
import 'widgets/tea_drawer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    // Слушаем провайдер списка
    final teaListAsync = ref.watch(teaListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(dotenv.env['APP_NAME'] ?? 'Tea App')),
      drawer: const TeaFilterDrawer(),
      body: teaListAsync.when(
        data: (teas) => RefreshIndicator(
          // Чтобы обновить, просто делаем refresh провайдера
          onRefresh: () async => ref.refresh(teaListProvider),
          child: teas.isEmpty
              ? const Center(child: Text("Список чая пока пуст"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: teas.length,
                  itemBuilder: (context, index) => TeaCard(tea: teas[index]),
                ),
        ),
        // Состояние загрузки
        loading: () => const Center(child: CircularProgressIndicator()),
        // Состояние ошибки
        error: (error, stack) {
          final errorText = error.toString().replaceFirst('Exception: ', '');

          // Вызываем модалку
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.showErrorDialog(errorText);
            }
          });

          return const Center(
            child: Text("Ошибка загрузки", style: TextStyle(color: Colors.grey)),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const AddScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;

                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
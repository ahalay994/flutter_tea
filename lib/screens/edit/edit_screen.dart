import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tea/api/dto/create_tea_dto.dart';
import 'package:tea/controllers/tea_controller.dart';
import 'package:tea/models/tea.dart';
import 'package:tea/utils/ui_helpers.dart';

class EditScreen extends ConsumerStatefulWidget {
  final TeaModel tea;

  const EditScreen({super.key, required this.tea});

  @override
  ConsumerState<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends ConsumerState<EditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _isConnected = true;
  StreamSubscription<bool>? _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tea.name);
    _descriptionController = TextEditingController(text: widget.tea.description ?? '');

    // Подписываемся на статус подключения
    _connectionSubscription = ref.read(teaControllerProvider).connectionStatusStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isConnected = isConnected;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _connectionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _saveTea() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isConnected) {
      context.showErrorDialog('Нет подключения к интернету. Проверьте подключение.');
      return;
    }

    final updatedTea = CreateTeaDto(
      name: _nameController.text,
      description: _descriptionController.text,
      images: [], // В оффлайн-режиме не поддерживаем изменение изображений
      appearanceId: widget.tea.appearance != null ? int.tryParse(widget.tea.appearance!) : null,
      countryId: widget.tea.country != null ? int.tryParse(widget.tea.country!) : null,
      flavors: widget.tea.flavors.map((f) => int.tryParse(f)).where((f) => f != null).cast<int>().toList(),
      typeId: widget.tea.type != null ? int.tryParse(widget.tea.type!) : null,
      temperature: widget.tea.temperature,
      weight: widget.tea.weight,
      brewingGuide: widget.tea.brewingGuide,
    );

    try {
      await ref.read(teaControllerProvider).updateTea(widget.tea.id, updatedTea, onSuccess: () {
        // Инвалидируем список чаёв
        ref.invalidate(teaListProvider);
      });
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorDialog('Ошибка при сохранении: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать чай'),
        actions: [
          IconButton(
            onPressed: _isConnected ? _saveTea : null, // Блокируем кнопку при отсутствии интернета
            icon: const Icon(Icons.save),
            tooltip: _isConnected ? 'Сохранить' : 'Нет подключения',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите название';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // Индикатор оффлайн режима
              if (!_isConnected)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8.0),
                  color: Colors.orange.shade100,
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Оффлайн режим - сохранение невозможно',
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
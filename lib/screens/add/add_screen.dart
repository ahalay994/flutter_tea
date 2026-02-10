import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tea/api/responses/appearance_response.dart';
import 'package:tea/api/responses/country_response.dart';
import 'package:tea/api/responses/flavor_response.dart';
import 'package:tea/api/responses/type_response.dart';
import 'package:tea/providers/metadata_provider.dart';
import 'package:tea/screens/add/widgets/rich_editor.dart';

import 'widgets/image_picker_section.dart';
import 'widgets/input_block.dart';
import 'widgets/multi_search_selector.dart';
import 'widgets/search_selector.dart';

class AddScreen extends ConsumerStatefulWidget {
  const AddScreen({super.key});

  @override
  ConsumerState<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends ConsumerState<AddScreen> {
  final List<XFile> _selectedImages = [];
  final _nameController = TextEditingController();
  CountryResponse? _selectedCountry;
  TypeResponse? _selectedType;
  AppearanceResponse? _selectedAppearance;
  List<FlavorResponse> _selectedFlavors = [];
  final _temperatureController = TextEditingController();
  final _weightController = TextEditingController();
  final QuillController _brewingGuide = QuillController.basic();
  final QuillController _description = QuillController.basic();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metadata = ref.watch(metadataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Добавить чай"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              // Логика сохранения (пока пусто)
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- БЛОК ФОТО ---
            InputBlock(
              label: "Изображение",
              icon: Icons.image_outlined,
              child: ImagePickerSection(
                selectedImages: _selectedImages,
                onImagesChanged: (newList) => setState(() {
                  _selectedImages.clear();
                  _selectedImages.addAll(newList);
                }),
              ),
            ),

            InputBlock(
              label: "Название",
              icon: Icons.title,
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: "Введите название"),
              ),
            ),

            // Сюда будем добавлять остальные поля (страна, тип и т.д.)
            InputBlock(
              label: "Страна",
              icon: Icons.public,
              child: SearchSelector<CountryResponse>(
                hint: "Выберите страну",
                items: metadata.countries,
                selectedValue: _selectedCountry,
                itemLabel: (item) => item.name, // Твой объект CountryResponse.name
                onCreate: (newName) => CountryResponse(id: 0, name: newName, createdAt: '', updatedAt: ''),
                onChanged: (val) => setState(() => _selectedCountry = val),
              ),
            ),

            // Сюда будем добавлять остальные поля (страна, тип и т.д.)
            InputBlock(
              label: "Тип чая",
              icon: Icons.eco,
              child: SearchSelector<TypeResponse>(
                hint: "Выберите тип чая",
                items: metadata.types,
                selectedValue: _selectedType,
                itemLabel: (item) => item.name, // Твой объект CountryResponse.name
                onCreate: (newName) => TypeResponse(id: 0, name: newName, createdAt: '', updatedAt: ''),
                onChanged: (val) => setState(() => _selectedType = val),
              ),
            ),

            InputBlock(
              label: "Внешний вид",
              icon: Icons.grain, // Попробуй эту для прессованного/рассыпного
              child: SearchSelector<AppearanceResponse>(
                hint: "Выберите внешний вид",
                items: metadata.appearances,
                selectedValue: _selectedAppearance,
                itemLabel: (item) => item.name,
                onCreate: (newName) => AppearanceResponse(id: 0, name: newName, createdAt: '', updatedAt: ''),
                onChanged: (val) => setState(() => _selectedAppearance = val),
              ),
            ),

            InputBlock(
              label: "Вкусы",
              icon: Icons.psychology_outlined,
              child: MultiSearchSelector<FlavorResponse>(
                hint: "Выберите вкусы",
                items: metadata.flavors,
                selectedValues: _selectedFlavors,
                itemLabel: (item) => item.name,
                onCreate: (newName) => FlavorResponse(id: 0, name: newName, createdAt: '', updatedAt: ''),
                onChanged: (newList) {
                  setState(() {
                    _selectedFlavors = List.from(newList);
                  });
                },
              ),
            ),

            InputBlock(
              label: "Температура заваривания",
              icon: Icons.thermostat,
              child: TextField(
                controller: _temperatureController,
                decoration: const InputDecoration(hintText: "Введите температуру"),
              ),
            ),

            InputBlock(
              label: "Вес",
              icon: Icons.scale,
              child: TextField(
                controller: _weightController,
                decoration: const InputDecoration(hintText: "Введите вес"),
              ),
            ),

            InputBlock(
              label: "Как лучше заварить?",
              icon: Icons.timer,
              child: RichEditor(controller: _brewingGuide),
            ),

            InputBlock(
              label: "Описание",
              icon: Icons.description,
              child: RichEditor(controller: _description),
            ),
          ],
        ),
      ),
    );
  }
}

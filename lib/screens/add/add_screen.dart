import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tea/api/dto/create_tea_dto.dart';
import 'package:tea/api/image_api.dart';
import 'package:tea/api/responses/appearance_response.dart';
import 'package:tea/api/responses/country_response.dart';
import 'package:tea/api/responses/flavor_response.dart';
import 'package:tea/api/responses/image_response.dart';
import 'package:tea/api/responses/type_response.dart';
import 'package:tea/controllers/tea_controller.dart';
import 'package:tea/providers/connection_status_provider.dart';
import 'package:tea/providers/metadata_provider.dart';
import 'package:tea/screens/add/widgets/rich_editor.dart';
import 'package:tea/utils/app_logger.dart';
import 'package:tea/utils/ui_helpers.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

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

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _temperatureController.dispose();
    _weightController.dispose();

    _brewingGuide.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_nameController.text.isEmpty) {
      context.showErrorDialog("Введите название чая");
      return;
    }

    context.showLoadingDialog();

    try {
      // ШАГ 1: Загрузка фото (выбросит Exception, если что-то не так)
      final List<ImageResponse> uploadedImages = await ref.read(imageApiProvider).uploadMultipleImages(_selectedImages);

      final brewingDelta = _brewingGuide.document.toDelta().toJson();
      final descriptionDelta = _description.document.toDelta().toJson();

      final brewingHtml = QuillDeltaToHtmlConverter(List<Map<String, dynamic>>.from(brewingDelta)).convert();
      final descriptionHtml = QuillDeltaToHtmlConverter(List<Map<String, dynamic>>.from(descriptionDelta)).convert();

      // ШАГ 2: Подготовка DTO
      final dto = CreateTeaDto(
        name: _nameController.text.trim(),
        images: uploadedImages,
        countryId: _selectedCountry?.id == 0 ? _selectedCountry?.name : _selectedCountry?.id,
        typeId: _selectedType?.id == 0 ? _selectedType?.name : _selectedType?.id,
        appearanceId: _selectedAppearance?.id == 0 ? _selectedAppearance?.name : _selectedAppearance?.id,
        flavors: _selectedFlavors.map((f) => f.id == 0 ? f.name : f.id).toList(),
        temperature: _temperatureController.text,
        weight: _weightController.text,
        brewingGuide: brewingHtml,
        description: descriptionHtml,
      );

      // ШАГ 3: Сохранение данных (теперь тоже выбросит Exception при ошибке)
      await ref.read(teaControllerProvider).createTeaWithResponse(
        dto,
        onSuccess: () {
          // Инвалидируем провайдер для страницы 1, чтобы обновить список чаёв
          ref.invalidate(teaListProvider(1));
          // Также инвалидируем фильтрованный список, если используется
          // ref.invalidate(filteredTeaListProvider); // Этот провайдер имеет параметры, которые нужно указать
          // Устанавливаем флаг обновления
          ref.read(refreshTeaListProvider.notifier).triggerRefresh();
        },
      );

      if (!mounted) return;

      context.hideLoading();
      context.showSuccessSnackBar("Чай успешно добавлен!");
      
      // Закрываем экран добавления и возвращаемся к главному экрану
      Navigator.of(context).pop(true);
    } catch (e) {
      // Сюда прилетит ЛЮБАЯ ошибка:
      // - Ошибка загрузки фото
      // - Ошибка сохранения чая (валидация бэкенда)
      // - Ошибка сети или JSON-парсинга
      AppLogger.error("Сбой в процессе сохранения", error: e);

      if (mounted) {
        context.hideLoading();
        context.showErrorDialog(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final metadataAsync = ref.watch(metadataProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isConnected = connectionStatus.when(
      data: (isConnected) => isConnected,
      loading: () => true, // По умолчанию считаем, что подключение есть
      error: (error, stack) => true, // При ошибке считаем, что подключение есть
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Добавить чай"),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  ),
                )
              : isConnected
                  ? IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: _isLoading ? null : _handleSave,
                    )
                  : const SizedBox(), // Скрываем кнопку при отсутствии подключения
        ],
      ),
      body: metadataAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка загрузки данных: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(metadataProvider);
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (metadata) => Column(
          children: [
            // Индикатор оффлайн режима
            if (!isConnected)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                color: Colors.orange.shade100,
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Оффлайн режим - добавление недоступно',
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            // Основной контент
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: AbsorbPointer(
                  // Отключаем все поля ввода при оффлайн режиме
                  absorbing: !isConnected,
                  child: Opacity(
                    // Делаем поля полупрозрачными в оффлайн режиме
                    opacity: isConnected ? 1.0 : 0.6,
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
                            itemLabel: (item) => item.name,
                            // Твой объект CountryResponse.name
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
                            itemLabel: (item) => item.name,
                            // Твой объект CountryResponse.name
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
                            decoration: const InputDecoration(hintText: "Введите температура"),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
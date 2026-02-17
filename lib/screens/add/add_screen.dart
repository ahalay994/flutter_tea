import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
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
import 'package:tea/providers/metadata_provider.dart';
import 'package:tea/screens/add/widgets/rich_editor.dart';
import 'package:tea/utils/app_logger.dart';
import 'package:tea/utils/ui_helpers.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'package:tea/widgets/animated_loader.dart';
import 'package:tea/screens/details/details_screen.dart';
import 'package:tea/models/tea.dart';

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
  final _brewingGuide = quill.QuillController.basic();
  final _description = quill.QuillController.basic();

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

    // Показываем полноэкранный лоадер
    setState(() {
      _isLoading = true;
    });

    try {
      // ШАГ 1: Загрузка фото (выбросит Exception, если что-то не так)
      final List<ImageResponse> uploadedImages = await ref.read(imageApiProvider).uploadMultipleImages(_selectedImages);

      final brewingDelta = _brewingGuide.document.toDelta().toJson();
      final descriptionDelta = _description.document.toDelta().toJson();

      final brewingHtml = QuillDeltaToHtmlConverter(brewingDelta).convert();
      final descriptionHtml = QuillDeltaToHtmlConverter(descriptionDelta).convert();

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

      // ШАГ 3: Сохранение данных и получение созданного чая
      final createdTeaResponse = await ref.read(teaControllerProvider).createTeaWithResponse(
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

      // Получаем метаданные для создания TeaModel
      final metadataAsync = ref.read(metadataProvider);
      if (metadataAsync.hasValue && metadataAsync.value != null) {
        final metadata = metadataAsync.value!;
        final createdTea = TeaModel.fromResponse(
          response: createdTeaResponse,
          countries: metadata.countries ?? [],
          types: metadata.types ?? [],
          appearances: metadata.appearances ?? [],
          flavors: metadata.flavors ?? [],
        );

        context.showSuccessSnackBar("Чай успешно добавлен!");
        
        // Переходим к экрану подробного просмотра созданного чая
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => TeaDetailScreen(tea: createdTea),
          ),
        );
      } else {
        context.showSuccessSnackBar("Чай успешно добавлен!");
        
        // Если метаданные не доступны, возвращаемся на главный экран
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      // Сюда прилетит ЛЮБАЯ ошибка:
      // - Ошибка загрузки фото
      // - Ошибка сохранения чая (валидация бэкенда)
      // - Ошибка сети или JSON-парсинга
      AppLogger.error("Сбой в процессе сохранения", error: e);

      if (mounted) {
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

    return FullScreenLoader(
      isLoading: _isLoading,
      child: Scaffold(
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
          data: (metadata) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF8F6FF), // Светло-фиолетовый
                  Colors.white,
                ],
              ),
            ),
            child: Column(
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
                              icon: Icons.local_cafe_outlined,
                              child: TextField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  hintText: "Введите название",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                  ),
                                ),
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
                                decoration: const InputDecoration(
                                  hintText: "Введите температура",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                  ),
                                ),
                              ),
                            ),

                            InputBlock(
                              label: "Вес",
                              icon: Icons.scale,
                              child: TextField(
                                controller: _weightController,
                                decoration: const InputDecoration(
                                  hintText: "Введите вес",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                  ),
                                ),
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
        ),
      ),
    );
  }
}
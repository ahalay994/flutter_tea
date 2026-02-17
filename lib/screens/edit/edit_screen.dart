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
import 'package:tea/models/tea.dart';
import 'package:tea/models/image.dart';
import 'package:tea/providers/metadata_provider.dart';
import 'package:tea/screens/add/widgets/input_block.dart';
import 'package:tea/screens/add/widgets/multi_search_selector.dart';
import 'package:tea/screens/add/widgets/rich_editor.dart';
import 'package:tea/screens/add/widgets/search_selector.dart';
import 'package:tea/screens/details/details_screen.dart';
import 'package:tea/screens/edit/widgets/editable_image_picker_section.dart';
import 'package:tea/utils/app_logger.dart';
import 'package:tea/utils/ui_helpers.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'package:tea/utils/html_to_delta_converter.dart';

class EditScreen extends ConsumerStatefulWidget {
  final TeaModel tea;

  const EditScreen({super.key, required this.tea});

  @override
  ConsumerState<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends ConsumerState<EditScreen> {
  // Список новых изображений (XFile)
  late List<XFile> _newImages;
  // Список существующих изображений, которые нужно сохранить (URL)
  late List<String> _existingImages;
  
  final _nameController = TextEditingController();
  CountryResponse? _selectedCountry;
  TypeResponse? _selectedType;
  AppearanceResponse? _selectedAppearance;
  List<FlavorResponse> _selectedFlavors = [];
  final _temperatureController = TextEditingController();
  final _weightController = TextEditingController();
  late quill.QuillController _brewingGuide;
  late quill.QuillController _description;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Инициализируем контроллеры
    _brewingGuide = quill.QuillController.basic();
    _description = quill.QuillController.basic();
    
    // Инициализируем поля данными из существующего чая
    _nameController.text = widget.tea.name;
    _temperatureController.text = widget.tea.temperature ?? '';
    _weightController.text = widget.tea.weight ?? '';
    
    // Инициализируем списки изображений
    // Исключаем заглушку из существующих изображений
    _existingImages = widget.tea.images.where((url) => !url.contains('default.png')).toList();
    _newImages = [];
    
    // Загружаем метаданные и находим соответствующие значения
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFormData();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _temperatureController.dispose();
    _weightController.dispose();

    _brewingGuide.dispose();
    _description.dispose();
    super.dispose();
  }

  // Инициализация формы с данными из существующего чая
  void _initializeFormData() async {
    final metadataAsync = ref.read(metadataProvider);
    
    if (metadataAsync case AsyncValue(hasValue: true, value: final metadata?) when metadata != null) {
      // Находим соответствующие значения по названию
      final teaCountry = widget.tea.country;
      if (teaCountry != null) {
        _selectedCountry = metadata.countries?.firstWhere(
          (c) => c.name == teaCountry, 
          orElse: () => CountryResponse(
            id: 0, 
            name: teaCountry, 
            createdAt: '', 
            updatedAt: ''
          ),
        );
      }
      
      final teaType = widget.tea.type;
      if (teaType != null) {
        _selectedType = metadata.types?.firstWhere(
          (t) => t.name == teaType, 
          orElse: () => TypeResponse(
            id: 0, 
            name: teaType, 
            createdAt: '', 
            updatedAt: ''
          ),
        );
      }
      
      final teaAppearance = widget.tea.appearance;
      if (teaAppearance != null) {
        _selectedAppearance = metadata.appearances?.firstWhere(
          (a) => a.name == teaAppearance, 
          orElse: () => AppearanceResponse(
            id: 0, 
            name: teaAppearance, 
            createdAt: '', 
            updatedAt: ''
          ),
        );
      }
      
      // Находим вкусы
      final flavors = <FlavorResponse>[];
      if (metadata.flavors != null) {
        for (final flavorName in widget.tea.flavors) {
          final flavor = metadata.flavors!.firstWhere(
            (f) => f.name == flavorName, 
            orElse: () => FlavorResponse(
              id: 0, 
              name: flavorName, 
              createdAt: '', 
              updatedAt: ''
            ),
          );
          flavors.add(flavor);
        }
      }
      _selectedFlavors = flavors;
      
      // Устанавливаем текст в контроллеры
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.tea.brewingGuide != null && widget.tea.brewingGuide!.isNotEmpty) {
          // Проверяем, содержит ли текст HTML-теги
          if (HtmlToDeltaConverter.isHtmlContent(widget.tea.brewingGuide!)) {
            // Если это HTML, преобразуем его в Delta формат
            _brewingGuide.document = HtmlToDeltaConverter.htmlToDelta(widget.tea.brewingGuide!);
          } else {
            // Если это обычный текст, загружаем как обычно
            _brewingGuide.document = quill.Document()..insert(0, widget.tea.brewingGuide!);
          }
        }
        
        if (widget.tea.description != null && widget.tea.description!.isNotEmpty) {
          // Проверяем, содержит ли текст HTML-теги
          if (HtmlToDeltaConverter.isHtmlContent(widget.tea.description!)) {
            // Если это HTML, преобразуем его в Delta формат
            _description.document = HtmlToDeltaConverter.htmlToDelta(widget.tea.description!);
          } else {
            // Если это обычный текст, загружаем как обычно
            _description.document = quill.Document()..insert(0, widget.tea.description!);
          }
        }
      });
      
      setState(() {}); // Обновляем состояние для отображения данных
    }
  }

  Future<void> _handleSave() async {
    if (_nameController.text.isEmpty) {
      context.showErrorDialog("Введите название чая");
      return;
    }

    // Проверяем подключение
    final isConnected = ref.read(teaControllerProvider).isConnected;
    if (!isConnected) {
      context.showErrorDialog('Нет подключения к интернету. Редактирование возможно только в онлайн-режиме.');
      return;
    }

    context.showLoadingDialog();

    try {
      // Загружаем новые изображения (если есть)
      List<ImageResponse> uploadedImages = [];
      if (_newImages.isNotEmpty) {
        uploadedImages = await ref.read(imageApiProvider).uploadMultipleImages(_newImages);
      }
      
      // Получаем оригинальный ответ с полными данными изображений (включая ID)
      final currentTeaResponse = await ref.read(teaControllerProvider).getTeaResponse(widget.tea.id);
      
      // Создаем ImageResponse для существующих изображений, которые не отмечены на удаление
      // Используем ID изображений из текущего чая
      final existingImageResponses = <ImageResponse>[];
      
      // Для каждого URL в _existingImages (это изображения, которые пользователь оставил)
      for (final url in _existingImages) {
        // Находим соответствующее изображение в оригинальном ответе по URL
        final imageInResponse = currentTeaResponse.images.firstWhere(
          (img) => img.url == url,
          orElse: () => ImageModel(
            id: null,
            name: url.split('/').last,
            status: 'finished',
            url: url,
            createdAt: null,
            updatedAt: null,
          ),
        );
        
        // Преобразуем найденное изображение в ImageResponse, сохранив ID
        existingImageResponses.add(ImageResponse(
          id: imageInResponse.id,
          name: imageInResponse.name,
          status: imageInResponse.status ?? 'finished',
          url: imageInResponse.url,
          createdAt: imageInResponse.createdAt,
          updatedAt: imageInResponse.updatedAt,
        ));
      }

      // Комбинируем существующие и новые изображения
      final allImages = [...existingImageResponses, ...uploadedImages];

      final brewingDelta = _brewingGuide.document.toDelta().toJson();
      final descriptionDelta = _description.document.toDelta().toJson();

      final brewingHtml = QuillDeltaToHtmlConverter(brewingDelta).convert();
      final descriptionHtml = QuillDeltaToHtmlConverter(descriptionDelta).convert();

      // Подготовка DTO для обновления
      final dto = CreateTeaDto(
        name: _nameController.text.trim(),
        images: allImages,
        countryId: _selectedCountry?.id == 0 ? _selectedCountry?.name : _selectedCountry?.id,
        typeId: _selectedType?.id == 0 ? _selectedType?.name : _selectedType?.id,
        appearanceId: _selectedAppearance?.id == 0 ? _selectedAppearance?.name : _selectedAppearance?.id,
        flavors: _selectedFlavors.map((f) => f.id == 0 ? f.name : f.id).toList(),
        temperature: _temperatureController.text,
        weight: _weightController.text,
        brewingGuide: brewingHtml,
        description: descriptionHtml,
      );

      // Обновление данных
      final updatedTea = await ref.read(teaControllerProvider).updateTea(
        widget.tea.id,
        dto,
        onSuccess: () => ref.read(refreshTeaListProvider.notifier).triggerRefresh(), // Обновляем список через флаг
      );

      if (!mounted) return;

      context.hideLoading();
      
      // Возвращаемся на предыдущий экран с обновленными данными
      if (Navigator.of(context).canPop()) {
        final metadataAsync = ref.read(metadataProvider);
        if (metadataAsync case AsyncValue(hasValue: true, value: final metadata?)) {
          final updatedTeaModel = TeaModel.fromResponse(
            response: updatedTea,
            countries: metadata.countries ?? [],
            types: metadata.types ?? [],
            appearances: metadata.appearances ?? [],
            flavors: metadata.flavors ?? [],
          );
          
          Navigator.of(context).pop(updatedTeaModel);
        } else {
          // Если метаданные не загружены, используем имеющийся чай
          Navigator.of(context).pop(widget.tea);
        }
      } else {
        // Если нельзя вернуться назад, получаем метаданные и создаем TeaModel из TeaResponse
        final metadataAsync = ref.read(metadataProvider);
        if (metadataAsync case AsyncValue(hasValue: true, value: final metadata?)) {
          final updatedTeaModel = TeaModel.fromResponse(
            response: updatedTea,
            countries: metadata.countries ?? [],
            types: metadata.types ?? [],
            appearances: metadata.appearances ?? [],
            flavors: metadata.flavors ?? [],
          );
          
          // Переходим к новому экрану деталей
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => TeaDetailScreen(tea: updatedTeaModel),
            ),
          );
        } else {
          // Если метаданные не загружены, используем имеющийся чай
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => TeaDetailScreen(tea: widget.tea),
            ),
          );
        }
      }
      
      // Показываем сообщение об успехе
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Чай успешно обновлён!"), backgroundColor: Colors.green)
          );
        }
      });
    } catch (e) {
      // Обработка ошибок
      AppLogger.error("Сбой в процессе обновления", error: e);

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
        title: const Text("Редактировать чай"),
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
                  ? IconButton(icon: const Icon(Icons.check), onPressed: (isConnected && !_isLoading) ? _handleSave : null)
                  : const SizedBox(), // Скрываем кнопку при отключенном интернете
        ],
      ),
      body: Column(
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
                      'Оффлайн режим - редактирование недоступно',
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          // Основной контент
          Expanded(
            child: metadataAsync.when(
              data: (metadata) {
                if (metadata == null) {
                  return const Center(child: Text('Ошибка загрузки данных'));
                }
                
                // Проверяем, инициализированы ли выбранные значения
                bool isInitialized = _selectedCountry != null || 
                                    _selectedType != null || 
                                    _selectedAppearance != null || 
                                    _selectedFlavors.isNotEmpty;
                
                // Если значения еще не инициализированы, но должны быть, и метаданные загружены,
                // запускаем инициализацию и показываем загрузку
                if (!isInitialized && 
                    (widget.tea.country != null || 
                     widget.tea.type != null || 
                     widget.tea.appearance != null || 
                     widget.tea.flavors.isNotEmpty)) {
                     
                  // Запускаем инициализацию если она еще не была выполнена
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _initializeFormData();
                    }
                  });
                  
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Загрузка данных чая...'),
                      ],
                    ),
                  );
                }
                
                return AbsorbPointer(
                  // Отключаем все поля ввода при оффлайн режиме
                  absorbing: !isConnected,
                  child: Opacity(
                    // Делаем поля полупрозрачными в оффлайн режиме
                    opacity: isConnected ? 1.0 : 0.6,
                    child: _buildFormContent(metadata),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
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
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFormContent(TeaMetadata metadata) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- БЛОК ФОТО ---
          InputBlock(
            label: "Изображение",
            icon: Icons.image_outlined,
            child: EditableImagePickerSection(
              images: [
                // Добавляем существующие изображения
                ..._existingImages.map((url) => EditableImage.existing(url)),
                // Добавляем новые изображения
                ..._newImages.map((file) => EditableImage.newImage(file)),
              ],
              onImagesChanged: (updatedList) => setState(() {
                _existingImages = updatedList
                    .where((img) => img.isExisting && !img.toDelete)
                    .map((img) => img.url!)
                    .toList();
                _newImages = updatedList
                    .where((img) => img.isNew)
                    .map((img) => img.file!)
                    .toList();
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
              items: metadata.countries ?? [],
              selectedValue: _selectedCountry,
              itemLabel: (item) => item.name,
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
              items: metadata.types ?? [],
              selectedValue: _selectedType,
              itemLabel: (item) => item.name,
              onCreate: (newName) => TypeResponse(id: 0, name: newName, createdAt: '', updatedAt: ''),
              onChanged: (val) => setState(() => _selectedType = val),
            ),
          ),

          InputBlock(
            label: "Внешний вид",
            icon: Icons.grain,
            child: SearchSelector<AppearanceResponse>(
              hint: "Выберите внешний вид",
              items: metadata.appearances ?? [],
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
              items: metadata.flavors ?? [],
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
    );
  }
}
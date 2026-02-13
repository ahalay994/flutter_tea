import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' as html_parser;
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
  late QuillController _brewingGuide;
  late QuillController _description;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Инициализируем контроллеры с пустыми документами
    _brewingGuide = QuillController.basic();
    _description = QuillController.basic();
    
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
    final metadata = ref.read(metadataProvider);
    
    // Находим соответствующие значения по названию
    if (widget.tea.country != null) {
      _selectedCountry = metadata.countries.firstWhere(
        (c) => c.name == widget.tea.country, 
        orElse: () => CountryResponse(
          id: 0, 
          name: widget.tea.country!, 
          createdAt: '', 
          updatedAt: ''
        ),
      );
    }
    
    if (widget.tea.type != null) {
      _selectedType = metadata.types.firstWhere(
        (t) => t.name == widget.tea.type, 
        orElse: () => TypeResponse(
          id: 0, 
          name: widget.tea.type!, 
          createdAt: '', 
          updatedAt: ''
        ),
      );
    }
    
    if (widget.tea.appearance != null) {
      _selectedAppearance = metadata.appearances.firstWhere(
        (a) => a.name == widget.tea.appearance, 
        orElse: () => AppearanceResponse(
          id: 0, 
          name: widget.tea.appearance!, 
          createdAt: '', 
          updatedAt: ''
        ),
      );
    }
    
    // Находим вкусы
    final flavors = <FlavorResponse>[];
    for (final flavorName in widget.tea.flavors) {
      final flavor = metadata.flavors.firstWhere(
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
    _selectedFlavors = flavors;
    
    // Преобразуем HTML в plain текст для редакторов
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.tea.brewingGuide != null) {
        try {
          // Удаляем HTML теги и получаем plain текст
          final document = html_parser.parse(widget.tea.brewingGuide!);
          final plainText = document.body?.text ?? widget.tea.brewingGuide!;
          _brewingGuide.document = Document()..insert(0, plainText);
        } catch (e) {
          // В случае ошибки просто вставляем оригинальный текст
          _brewingGuide.document = Document()..insert(0, widget.tea.brewingGuide!);
        }
      }
      
      if (widget.tea.description != null) {
        try {
          // Удаляем HTML теги и получаем plain текст
          final document = html_parser.parse(widget.tea.description!);
          final plainText = document.body?.text ?? widget.tea.description!;
          _description.document = Document()..insert(0, plainText);
        } catch (e) {
          // В случае ошибки просто вставляем оригинальный текст
          _description.document = Document()..insert(0, widget.tea.description!);
        }
      }
    });
    
    setState(() {}); // Обновляем состояние для отображения данных
  }

  Future<void> _handleSave() async {
    if (_nameController.text.isEmpty) {
      context.showErrorDialog("Введите название чая");
      return;
    }

    context.showLoadingDialog();

    try {
      // Загружаем новые изображения (если есть)
      List<ImageResponse> uploadedImages = [];
      if (_newImages.isNotEmpty) {
        uploadedImages = await ref.read(imageApiProvider).uploadMultipleImages(_newImages);
      }
      
      // Получаем текущий чай с полной информацией об изображениях
      final currentTea = await ref.read(teaControllerProvider).getTea(widget.tea.id);
      
      // Создаем ImageResponse для существующих изображений, которые не отмечены на удаление
      // Используем ID изображений из текущего чая
      final existingImageResponses = <ImageResponse>[];
      
      // Для каждого URL в _existingImages (это изображения, которые пользователь оставил)
      for (final url in _existingImages) {
        // Находим соответствующее изображение в текущем чае по URL
        final currentImage = currentTea.images.firstWhere(
          (img) => img.url == url,
          orElse: () => ImageModel(
            id: null, // Если не найдено, создаем с null ID
            name: url.split('/').last,
            status: 'finished',
            url: url,
            createdAt: null,
            updatedAt: null,
          ),
        );
        
        // Преобразуем в ImageResponse, сохраняя ID если оно было
        existingImageResponses.add(ImageResponse(
          id: currentImage.id,
          name: currentImage.name,
          status: currentImage.status,
          url: currentImage.url,
          createdAt: currentImage.createdAt,
          updatedAt: currentImage.updatedAt,
        ));
      }

      // Комбинируем существующие и новые изображения
      final allImages = [...existingImageResponses, ...uploadedImages];

      final brewingDelta = _brewingGuide.document.toDelta().toJson();
      final descriptionDelta = _description.document.toDelta().toJson();

      final brewingHtml = QuillDeltaToHtmlConverter(List<Map<String, dynamic>>.from(brewingDelta)).convert();
      final descriptionHtml = QuillDeltaToHtmlConverter(List<Map<String, dynamic>>.from(descriptionDelta)).convert();

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
        onSuccess: () => ref.invalidate(teaListProvider), // Инвалидируем список
      );

      if (!mounted) return;

      context.hideLoading();
      
      // Возвращаемся на предыдущий экран с обновленными данными
      if (Navigator.of(context).canPop()) {
        // Получаем метаданные и создаем TeaModel из TeaResponse
        final metadata = ref.read(metadataProvider);
        final updatedTeaModel = TeaModel.fromResponse(
          response: updatedTea,
          countries: metadata.countries,
          types: metadata.types,
          appearances: metadata.appearances,
          flavors: metadata.flavors,
        );
        
        Navigator.of(context).pop(updatedTeaModel);
      } else {
        // Если нельзя вернуться назад, получаем метаданные и создаем TeaModel из TeaResponse
        final metadata = ref.read(metadataProvider);
        final updatedTeaModel = TeaModel.fromResponse(
          response: updatedTea,
          countries: metadata.countries,
          types: metadata.types,
          appearances: metadata.appearances,
          flavors: metadata.flavors,
        );
        
        // Переходим к новому экрану деталей
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => TeaDetailScreen(tea: updatedTeaModel),
          ),
        );
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
    final metadata = ref.watch(metadataProvider);

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
              : IconButton(icon: const Icon(Icons.check), onPressed: _isLoading ? null : _handleSave),
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
                items: metadata.countries,
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
                items: metadata.types,
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
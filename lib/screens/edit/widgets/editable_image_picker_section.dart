import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditableImage {
  final String? url; // URL для существующего изображения
  final XFile? file; // XFile для нового изображения
  bool toDelete; // Флаг удаления для существующего изображения

  EditableImage.existing(this.url) : file = null, toDelete = false;
  EditableImage.newImage(this.file) : url = null, toDelete = false;

  bool get isNew => file != null;
  bool get isExisting => url != null;
}

class EditableImagePickerSection extends StatefulWidget {
  final List<EditableImage> images;
  final Function(List<EditableImage>) onImagesChanged;

  const EditableImagePickerSection({
    super.key,
    required this.images,
    required this.onImagesChanged,
  });

  @override
  State<EditableImagePickerSection> createState() => _EditableImagePickerSectionState();
}

class _EditableImagePickerSectionState extends State<EditableImagePickerSection> {
  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> files = await picker.pickMultiImage();
    if (files.isNotEmpty) {
      final newImages = files.map((file) => EditableImage.newImage(file)).toList();
      widget.onImagesChanged([...widget.images, ...newImages]);
    }
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();

    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (photo != null) {
      final newImage = EditableImage.newImage(photo);
      widget.onImagesChanged([...widget.images, newImage]);
    }
  }

  Future<void> _showPickerOptions(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImages();
                },
                icon: const Icon(Icons.photo_library),
                label: const Text('Открыть галерею'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),

              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Открыть камеру'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Кнопка "+"
              GestureDetector(
                onTap: () => _showPickerOptions(context),
                child: Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: Icon(Icons.add_a_photo, color: Colors.grey[600]),
                ),
              ),

              const SizedBox(width: 10),

              // Список изображений (новые и существующие)
                              ...widget.images.asMap().entries.map((entry) {
                              int index = entry.key;
                              EditableImage image = entry.value;
                              
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: image.toDelete ? Colors.red : Colors.grey[400]!,
                                          width: image.toDelete ? 2 : 1,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: image.isNew
                                            ? (kIsWeb
                                                ? Image.network(image.file!.path, fit: BoxFit.cover)
                                                : Image.file(File(image.file!.path), fit: BoxFit.cover))
                                            : Image.network(image.url!, fit: BoxFit.cover),
                                      ),
                                    ),
                                    Positioned(
                                      top: 5,
                                      right: 5,
                                      child: GestureDetector(
                                        onTap: () {
                                          if (image.isExisting) {
                                            // Для существующего изображения устанавливаем флаг удаления
                                            final updatedImages = List<EditableImage>.from(widget.images);
                                            updatedImages[index] = EditableImage.existing(image.url!)
                                              ..toDelete = !image.toDelete;
                                            widget.onImagesChanged(updatedImages);
                                          } else {
                                            // Для нового изображения удаляем его
                                            final updatedImages = List<EditableImage>.from(widget.images);
                                            updatedImages.removeAt(index);
                                            widget.onImagesChanged(updatedImages);
                                          }
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: image.isExisting && image.toDelete 
                                              ? Colors.green 
                                              : Colors.black54, 
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            image.isExisting && !image.toDelete 
                                              ? Icons.close 
                                              : Icons.check,
                                            color: Colors.white, 
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (image.isExisting && image.toDelete)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.5),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),            ],
          ),
        ),
      ],
    );
  }
}
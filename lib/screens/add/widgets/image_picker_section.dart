import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImagePickerSection extends StatelessWidget {
  final List<XFile> selectedImages;
  final Function(List<XFile>) onImagesChanged;

  const ImagePickerSection({super.key, required this.selectedImages, required this.onImagesChanged});

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      onImagesChanged([...selectedImages, ...images]);
    }
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();

    // Ключевой момент: source: ImageSource.camera
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80, // немного сжимаем, чтобы приложение не лагало
    );

    if (photo != null) {
      // Добавляем новое фото к уже выбранным
      onImagesChanged([...selectedImages, photo]);
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
                  minimumSize: const Size(double.infinity, 50), // Кнопка на всю ширину
                ),
              ),

              const SizedBox(height: 10), // Отступ между кнопками
              // КНОПКА КАМЕРА
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Открыть камеру'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200], // Другой цвет, чтобы различать
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

              // Список выбранных фото
              ...selectedImages.asMap().entries.map((entry) {
                int index = entry.key;
                XFile file = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                            ? CachedNetworkImage(
                                imageUrl: file.path,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
                              )
                            : Image.file(File(file.path), width: 100, height: 100, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: GestureDetector(
                          onTap: () => onImagesChanged(List.from(selectedImages)..removeAt(index)),
                          child: Container(
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }
}

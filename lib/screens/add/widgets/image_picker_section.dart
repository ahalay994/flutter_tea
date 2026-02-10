import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
                onTap: _pickImages,
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
                            ? Image.network(file.path, width: 100, height: 100, fit: BoxFit.cover)
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

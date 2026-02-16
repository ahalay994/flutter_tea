import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tea/api/responses/image_response.dart';
import 'package:tea/services/supabase_service.dart';
import 'package:tea/utils/app_logger.dart';

final imageApiProvider = Provider((ref) => ImageApi());

class ImageApi {
  final SupabaseService _supabaseService = SupabaseService();

  Future<ImageResponse?> uploadSingleImage(XFile image) async {
    try {
      AppLogger.debug('Начинаем загрузку изображения в Supabase: ${image.name}');
      
      // Читаем байты изображения
      final bytes = await image.readAsBytes();
      AppLogger.debug('Прочитали байты изображения: ${bytes.length} байт');
      
      // Формируем имя файла
      final fileName = 'public/${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      AppLogger.debug('Начинаем загрузку файла байтов в Supabase: $fileName');
      
      // Загружаем в Supabase (теперь с оптимизацией внутри сервиса)
      final url = await _supabaseService.uploadFileBytes(
        filePath: fileName,
        fileBytes: Uint8List.fromList(bytes),
      );
      
      AppLogger.debug('Изображение успешно загружено в Supabase: ${image.name}');
      
      // Возвращаем ImageResponse с правильной структурой, как ожидает бэкенд
      return ImageResponse(
        id: null, // будет установлен сервером
        name: image.name,
        status: 'pending', // Устанавливаем статус pending, как ожидает бэкенд
        url: url,
        createdAt: null,
        updatedAt: null,
      );
    } catch (e) {
      AppLogger.error('Ошибка при загрузке файла байтов в Supabase', error: e);
      rethrow;
    }
  }

  Future<List<ImageResponse>> uploadMultipleImages(List<XFile> images) async {
    final List<ImageResponse> results = [];
    
    for (int i = 0; i < images.length; i++) {
      AppLogger.debug('Загрузка изображения ${i + 1} из ${images.length}: ${images[i].name}');
      
      try {
        final res = await uploadSingleImage(images[i]);
        if (res != null) results.add(res);
      } catch (e) {
        AppLogger.error('Поймана ошибка при загрузке изображения в Supabase ${images[i].name}', error: e);
        rethrow; // Это гарантирует, что в AddScreen сработает блок catch и покажется модалка
      }
    }
    
    AppLogger.debug('Начинаем загрузку ${results.length} изображений в Supabase');
    return results;
  }
}
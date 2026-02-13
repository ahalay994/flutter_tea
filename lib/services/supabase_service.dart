import 'dart:typed_data';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;

class SupabaseService {
  static SupabaseClient? _client;

  void init(String supabaseUrl, String supabaseKey) {
    _client = SupabaseClient(supabaseUrl, supabaseKey);
  }

  SupabaseClient get supabase {
    if (_client == null) {
      throw Exception('SupabaseService not initialized. Call init() first.');
    }
    return _client!;
  }

  // Метод для оптимизации изображения (аналогично серверной обработке)
  Uint8List _optimizeImage(Uint8List imageBytes) {
    // Декодируем изображение
    img.Image? decodedImage = img.decodeImage(imageBytes);
    
    if (decodedImage == null) {
      // Если не удалось декодировать, возвращаем оригинальные байты
      return imageBytes;
    }
    
    // Изменяем размер изображения при необходимости (например, ограничиваем до 1920px по большей стороне)
    int width = decodedImage.width;
    int height = decodedImage.height;
    
    if (width > 1920 || height > 1920) {
      double ratio = 1920.0 / (width > height ? width : height);
      width = (width * ratio).round();
      height = (height * ratio).round();
      decodedImage = img.copyResize(decodedImage, width: width, height: height);
    }
    
    // Конвертируем в JPG с качеством 75 (как альтернатива WebP)
    Uint8List optimizedBytes = Uint8List.fromList(
      img.encodeJpg(decodedImage, quality: 75)
    );
    
    return optimizedBytes;
  }

  Future<String> uploadFileBytes({
    String bucketName = 'tea',
    String? filePath,
    required Uint8List fileBytes,
  }) async {
    try {
      // Оптимизируем изображение перед загрузкой
      Uint8List optimizedBytes = _optimizeImage(fileBytes);
      
      // Загружаем оптимизированное изображение
      // Используем uploadBinary для загрузки байтов
      await supabase.storage
          .from(bucketName)
          .uploadBinary(filePath ?? '', optimizedBytes, fileOptions: FileOptions(upsert: true));
      
      // Получаем публичный URL
      final publicUrl = supabase.storage
          .from(bucketName)
          .getPublicUrl(filePath ?? '');
      
      return publicUrl;
    } catch (e) {
      throw Exception('Ошибка при загрузке файла в Supabase: $e');
    }
  }

  Future<List<String>> listFiles({
    String bucketName = 'tea',
    String? path,
  }) async {
    try {
      final response = await supabase.storage
          .from(bucketName)
          .list(path: path ?? '');
      
      return response.map((file) => file.name).toList();
    } catch (e) {
      throw Exception('Ошибка при получении списка файлов из Supabase: $e');
    }
  }
}
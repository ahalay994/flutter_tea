import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:tea_multitenant/utils/app_config.dart';
import 'package:tea_multitenant/utils/app_logger.dart';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;

class DeviceService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String> getOrRegisterDevice() async {
    // Попробуем получить deviceId из хранилища
    String? deviceId = await _storage.read(key: 'device_id');
    if (deviceId != null) {
      AppLogger.debug('Устройство уже зарегистрировано с ID: $deviceId');
      return deviceId;
    }

    AppLogger.debug('Устройство не зарегистрировано, начинаем процесс регистрации');
    
    deviceId = await _registerDevice();
    await _storage.write(key: 'device_id', value: deviceId);
    return deviceId;
  }

  Future<String> _registerDevice() async {
    // Генерируем уникальный токен устройства
    final deviceToken = const Uuid().v4();
    final deviceName = await _getDeviceName();

    AppLogger.debug('Текущий AppConfig.apiUrl: ${AppConfig.apiUrl}');
    final url = '${AppConfig.apiUrl}/device/register';
    AppLogger.debug('Попытка регистрации устройства: $deviceName (token: $deviceToken)');
    AppLogger.debug('Полный URL регистрации: $url');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'deviceToken': deviceToken,
        'name': deviceName,
      }),
    );

    AppLogger.debug('Статус ответа от сервера: ${response.statusCode}');
    AppLogger.debug('Тело ответа от сервера: ${response.body}');

    if (response.statusCode ~/ 100 != 2) {
      AppLogger.error('Ошибка регистрации устройства: ${response.body}');
      throw Exception('Failed to register device: ${response.body}');
    }

    try {
      final data = jsonDecode(response.body);
      final deviceData = data['data'];
      AppLogger.success('Успешно зарегистрировано устройство с ID: ${deviceData['deviceId']}');
      return deviceData['deviceId'];
    } catch (e) {
      AppLogger.error('Ошибка разбора ответа от сервера: $e');
      AppLogger.error('Тело ответа: ${response.body}');
      throw Exception('Failed to parse registration response: $e');
    }
  }

  Future<String> _getDeviceName() async {
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await DeviceInfoPlugin().androidInfo;
        return 'Android ${androidInfo.model}';
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await DeviceInfoPlugin().iosInfo;
        return 'iOS ${iosInfo.name ?? iosInfo.model}';
      } else {
        return 'Flutter Device';
      }
    } catch (e) {
      return 'Flutter Device';
    }
  }
}
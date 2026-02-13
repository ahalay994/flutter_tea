import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tea/api/dto/create_tea_dto.dart';
import 'package:tea/models/tea.dart';
import 'package:tea/services/tea_service.dart';
import 'package:tea/utils/app_logger.dart';

final teaControllerProvider = Provider((ref) => TeaController());

final teaListProvider = FutureProvider<List<TeaModel>>((ref) {
  final controller = ref.watch(teaControllerProvider);
  return controller.fetchFullTeas(ref);
});

class TeaController {
  final TeaService _teaService = TeaService();

  Future<List<TeaModel>> fetchFullTeas(Ref ref) async {
    try {
      return await _teaService.fetchFullTeas(ref);
    } catch (e, stack) {
      AppLogger.error('Ошибка в TeaController', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> createTea(CreateTeaDto dto, {required VoidCallback onSuccess}) async {
    try {
      await _teaService.createTea(dto: dto, onSuccess: onSuccess);
    } catch (e, stack) {
      AppLogger.error('Ошибка в TeaController при создании чая', error: e, stackTrace: stack);
      rethrow;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tea/providers/theme_provider.dart';

class ThemeSelectorModal extends ConsumerStatefulWidget {
  const ThemeSelectorModal({super.key});

  @override
  ConsumerState<ThemeSelectorModal> createState() => _ThemeSelectorModalState();
}

class _ThemeSelectorModalState extends ConsumerState<ThemeSelectorModal> {
  late Color _primaryColor;
  late Color _secondaryColor;

  @override
  void initState() {
    super.initState();
    final colors = ref.read(customColorsProvider);
    _primaryColor = colors.$1;
    _secondaryColor = colors.$2;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Тема'),
      content: StatefulBuilder(
        builder: (context, setState) {
          return SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Основной цвет'),
                            const SizedBox(height: 4),
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Material(
                                color: _primaryColor,
                                child: InkWell(
                                  onTap: () async {
                                    final color = await _showColorPicker(context, _primaryColor);
                                    if (color != null) {
                                      setState(() {
                                        _primaryColor = color;
                                      });
                                    }
                                  },
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Вторичный цвет'),
                            const SizedBox(height: 4),
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Material(
                                color: _secondaryColor,
                                child: InkWell(
                                  onTap: () async {
                                    final color = await _showColorPicker(context, _secondaryColor);
                                    if (color != null) {
                                      setState(() {
                                        _secondaryColor = color;
                                      });
                                    }
                                  },
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отмена')),
        TextButton(
          onPressed: () {
            ThemeManager().setCustomColors(_primaryColor, _secondaryColor);
            Navigator.of(context).pop();
          },
          child: const Text('Применить'),
        ),
      ],
    );
  }

  Future<Color?> _showColorPicker(BuildContext context, Color initialColor) async {
    Color currentColor = initialColor;

    return showDialog<Color>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Выберите цвет'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: (color) {
                currentColor = color;
              },
              colorPickerWidth: 300,
              pickerAreaHeightPercent: 0.7,
              enableAlpha: false,
              displayThumbColor: true,
              showLabel: true,
              paletteType: PaletteType.hsv,
              pickerAreaBorderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отмена')),
            TextButton(onPressed: () => Navigator.of(context).pop(currentColor), child: const Text('Выбрать')),
          ],
        );
      },
    );
  }
}

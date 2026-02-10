import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class RichEditor extends StatelessWidget {
  final QuillController controller;
  final String placeholder;

  const RichEditor({super.key, required this.controller, this.placeholder = 'Опишите ваш чай...'});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Панель инструментов (Toolbar)
          QuillSimpleToolbar(
            controller: controller,
            config: const QuillSimpleToolbarConfig(
              showFontSize: false, // Упростим для начала
              showFontFamily: false,
              multiRowsDisplay: false,
            ),
          ),
          const Divider(height: 1),
          // Поле ввода (Editor)
          Container(
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(minHeight: 150, maxHeight: 300),
            child: QuillEditor.basic(
              controller: controller,
              config: QuillEditorConfig(
                placeholder: placeholder,
                autoFocus: false,
                expands: false,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class RichEditor extends StatelessWidget {
  final quill.QuillController controller;

  const RichEditor({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            height: 40,
            child: quill.QuillToolbar(
              controller: controller,
              configurations: quill.QuillToolbarConfigurations(
                showBoldButton: true,
                showItalicButton: true,
                showUnderlineButton: true,
                showListButton: true,
                showHeaderButton: true,
              ),
            ),
          ),
          const Divider(height: 1),
          Container(
            height: 100,
            child: quill.QuillEditor(
              controller: controller,
              scrollController: ScrollController(),
              scrollable: true,
              focusNode: FocusNode(),
              autoFocus: false,
              readOnly: false,
              placeholder: 'Введите текст...',
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
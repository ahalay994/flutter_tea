import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class RichEditor extends StatelessWidget {
  final quill.QuillController controller;
  final String placeholder;

  const RichEditor({super.key, required this.controller, this.placeholder = 'Опишите ваш чай...'});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            height: 40,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.format_bold),
                    onPressed: () {
                      controller.formatSelection(quill.Attribute.bold);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_italic),
                    onPressed: () {
                      controller.formatSelection(quill.Attribute.italic);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_underline),
                    onPressed: () {
                      controller.formatSelection(quill.Attribute.underline);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_list_bulleted),
                    onPressed: () {
                      controller.formatSelection(quill.Attribute.ul);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_list_numbered),
                    onPressed: () {
                      controller.formatSelection(quill.Attribute.ol);
                    },
                  ),


                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: quill.QuillEditor(
              controller: controller,
              scrollController: ScrollController(),
              focusNode: FocusNode(),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

class MultiSearchSelector<T> extends StatelessWidget {
  final String hint;
  final List<T> items;
  final List<T> selectedValues;
  final String Function(T) itemLabel;
  final T Function(String) onCreate;
  final Function(List<T>) onChanged;

  const MultiSearchSelector({
    super.key,
    required this.hint,
    required this.items,
    required this.selectedValues,
    required this.itemLabel,
    required this.onCreate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<T>.multiSelection(
      items: (filter, loadProps) => items,
      itemAsString: itemLabel,
      selectedItems: selectedValues,
      onChanged: onChanged,
      compareFn: (item1, item2) => itemLabel(item1) == itemLabel(item2),
      popupProps: PopupPropsMultiSelection.modalBottomSheet(
        modalBottomSheetProps: ModalBottomSheetProps(backgroundColor: Theme.of(context).primaryColor.withOpacity(0.05)),
        showSearchBox: true,
        showSelectedItems: true,
        emptyBuilder: (context, search) => Center(
          child: TextButton.icon(
            icon: Icon(Icons.add, color: Theme.of(context).primaryColor),
            label: Text("Добавить '$search'"),
            onPressed: () {
              final newItem = onCreate(search);
              // Добавляем новый элемент к уже выбранным и пушим наверх
              onChanged([...selectedValues, newItem]);
              Navigator.pop(context);
            },
          ),
        ),
      ),
      decoratorProps: DropDownDecoratorProps(
        baseStyle: TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3)),
          ),
        ),
      ),
    );
  }
}

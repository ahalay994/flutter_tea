import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

class SearchSelector<T> extends StatelessWidget {
  final String hint;
  final List<T> items;
  final T? selectedValue;
  final String Function(T) itemLabel;
  final T Function(String) onCreate;
  final Function(T?) onChanged;

  const SearchSelector({
    super.key,
    required this.hint,
    required this.items,
    required this.selectedValue,
    required this.itemLabel,
    required this.onCreate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<T>(
      // В новых версиях используется этот параметр для списка
      items: (filter, loadProps) => items,
      itemAsString: (T item) => itemLabel(item),
      selectedItem: selectedValue,
      onChanged: onChanged,
      compareFn: (item1, item2) {
        if (item1 == null || item2 == null) return false;
        return (item1 as dynamic).id == (item2 as dynamic).id;
      },

      // Настройка внешнего вида (версия 6.0+)
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),

      // Настройка окна поиска
      popupProps: PopupProps.menu(
        showSearchBox: true,
        emptyBuilder: (context, search) => Center(
          child: TextButton.icon(
            icon: const Icon(Icons.add),
            label: Text("Добавить '$search'"),
            onPressed: () {
              final newItem = onCreate(search);
              onChanged(newItem);
              Navigator.pop(context); // Закрываем выпадашку
            },
          ),
        ),
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: "Поиск...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }
}

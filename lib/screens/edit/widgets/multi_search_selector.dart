import 'package:flutter/material.dart';

class MultiSearchSelector<T> extends StatefulWidget {
  final String hint;
  final List<T> items;
  final List<T> selectedValues;
  final String Function(T item) itemLabel;
  final T Function(String newName) onCreate;
  final void Function(List<T> values) onChanged;

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
  State<MultiSearchSelector<T>> createState() => _MultiSearchSelectorState<T>();
}

class _MultiSearchSelectorState<T> extends State<MultiSearchSelector<T>> {
  final TextEditingController _textController = TextEditingController();
  bool _showOptions = false;
  List<T> _filteredItems = [];
  List<T> _selectedItems = [];

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.selectedValues);
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items.where((item) => !_selectedItems.contains(item)).toList();
      } else {
        _filteredItems = widget.items
            .where((item) =>
                !_selectedItems.contains(item) &&
                widget.itemLabel(item).toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _removeItem(T item) {
    setState(() {
      _selectedItems.remove(item);
    });
    widget.onChanged(_selectedItems);
  }

  void _addItem(T item) {
    setState(() {
      _selectedItems.add(item);
      _textController.clear();
      _showOptions = false;
    });
    widget.onChanged(_selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _textController,
          decoration: InputDecoration(
            hintText: widget.hint,
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) {
            _filterItems(value);
            setState(() {
              _showOptions = value.isNotEmpty;
            });
          },
          onTap: () {
            _filterItems("");
            setState(() {
              _showOptions = true;
            });
          },
        ),
        const SizedBox(height: 8),
        // Отображение выбранных значений
        if (_selectedItems.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedItems.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.itemLabel(item)),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _removeItem(item),
                      child: const Icon(Icons.close, size: 16, color: Colors.blue),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        if (_showOptions && _filteredItems.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return ListTile(
                  title: Text(widget.itemLabel(item)),
                  onTap: () => _addItem(item),
                );
              },
            ),
          ),
        if (_showOptions && _filteredItems.isEmpty && _textController.text.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListTile(
              title: Text('Создать "${_textController.text}"'),
              onTap: () {
                final newItem = widget.onCreate(_textController.text);
                _addItem(newItem);
              },
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
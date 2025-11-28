import 'package:flutter/material.dart';
import '../models/dropdown_model.dart';
import '../models/supplier_model.dart';
import '../models/item_model.dart';

class DropdownField<T> extends StatelessWidget {
  final String label;
  final String? hint;
  final T? value;
  final List<T> items;
  final Function(T?) onChanged;
  final String? Function(T?)? validator;
  final bool isRequired;
  final bool enabled;

  const DropdownField({
    super.key,
    required this.label,
    this.hint,
    this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.isRequired = false,
    this.enabled = true,
  });

  String _getDisplayText(T item) {
    if (item is DropdownModel) {
      return item.name;
    } else if (item is SupplierModel) {
      return item.name;
    } else if (item is ItemModel) {
      return item.name;
    }
    return item.toString();
  }

  int? _getId(T item) {
    if (item is DropdownModel) {
      return item.id;
    } else if (item is SupplierModel) {
      return item.id;
    } else if (item is ItemModel) {
      return item.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return TextFormField(
        enabled: false,
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          hintText: 'No data available',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }

    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label + (isRequired ? ' *' : ''),
        hintText: hint ?? 'Select $label',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
      ),
      items: items.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            _getDisplayText(item),
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
      validator: validator,
      isExpanded: true,
      icon: const Icon(Icons.arrow_drop_down),
    );
  }
}


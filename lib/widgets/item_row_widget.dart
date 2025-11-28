import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/purchase_item_model.dart';
import '../models/dropdown_model.dart';
import '../models/item_model.dart';
import '../providers/master_provider.dart';
import 'dropdown_field.dart';

class ItemRowWidget extends StatefulWidget {
  final int index;
  final PurchaseItemModel item;
  final Function(PurchaseItemModel) onUpdate;
  final VoidCallback onRemove;

  const ItemRowWidget({
    super.key,
    required this.index,
    required this.item,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<ItemRowWidget> createState() => _ItemRowWidgetState();
}

class _ItemRowWidgetState extends State<ItemRowWidget> {
  late PurchaseItemModel _item;
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _item = PurchaseItemModel(
      itemId: widget.item.itemId,
      qtyRequired: widget.item.qtyRequired,
      unitPrice: widget.item.unitPrice,
      gstPercent: widget.item.gstPercent,
    );
    _qtyController.text = widget.item.qtyRequired > 0 
        ? widget.item.qtyRequired.toString() 
        : '';
    _priceController.text = widget.item.unitPrice > 0 
        ? widget.item.unitPrice.toString() 
        : '';
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _updateItem() {
    widget.onUpdate(_item);
  }

  ItemModel? _getSelectedItem() {
    if (_item.itemId == null) return null;
    final masterProvider = Provider.of<MasterProvider>(context, listen: false);
    try {
      return masterProvider.items.firstWhere(
        (item) => item.id == _item.itemId,
      );
    } catch (e) {
      return null;
    }
  }

  // Removed itemTypeId, godownId, gstClassificationId, statusId as per API requirements
  // These fields are no longer needed in the item model

  @override
  Widget build(BuildContext context) {
    final masterProvider = Provider.of<MasterProvider>(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Item ${widget.index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onRemove,
                  tooltip: 'Remove item',
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Item dropdown
            DropdownField<ItemModel>(
              key: ValueKey('item_${widget.index}_${_item.itemId}'),
              label: 'Item',
              value: _getSelectedItem(),
              items: masterProvider.items,
              onChanged: (value) {
                setState(() {
                  _item.itemId = value?.id;
                });
                _updateItem();
              },
              isRequired: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Qty Required
                Expanded(
                  child: TextFormField(
                    controller: _qtyController,
                    decoration: InputDecoration(
                      labelText: 'Qty Required *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final qty = double.tryParse(value) ?? 0.0;
                      setState(() {
                        _item.qtyRequired = qty;
                      });
                      _updateItem();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Unit Price
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Unit Price *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final price = double.tryParse(value) ?? 0.0;
                      setState(() {
                        _item.unitPrice = price;
                      });
                      _updateItem();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // GST Percent
            TextFormField(
              initialValue: _item.gstPercent != null && _item.gstPercent! > 0 
                  ? _item.gstPercent.toString() 
                  : '',
              decoration: InputDecoration(
                labelText: 'GST Percent (%)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: '0-100',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                final gst = double.tryParse(value) ?? 0.0;
                setState(() {
                  _item.gstPercent = gst > 0 ? gst : null;
                });
                _updateItem();
              },
            ),
          ],
        ),
      ),
    );
  }
}


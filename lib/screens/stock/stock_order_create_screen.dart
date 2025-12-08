import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/stock_order_provider.dart';
import '../../providers/master_provider.dart';
import '../../models/dropdown_model.dart';
import '../../models/item_model.dart';
import '../../models/stock_order_model.dart';
import '../../widgets/shimmer_loader.dart';
import '../../services/auth_service.dart';
import 'stock_order_list_screen.dart';

class StockOrderCreateScreen extends StatefulWidget {
  const StockOrderCreateScreen({super.key});

  @override
  State<StockOrderCreateScreen> createState() => _StockOrderCreateScreenState();
}

class _StockOrderCreateScreenState extends State<StockOrderCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _remarksController = TextEditingController();
  
  List<StockOrderItemModel> _items = [];
  int? _selectedItemId;
  final _quantityController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMasterData();
    });
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadMasterData() async {
    final masterProvider = Provider.of<MasterProvider>(context, listen: false);
    if (masterProvider.activeItems.isEmpty) {
      await masterProvider.loadAllMasterData();
    }
  }

  void _addItem() {
    if (_selectedItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an item')),
      );
      return;
    }

    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }

    final masterProvider = Provider.of<MasterProvider>(context, listen: false);
    final item = masterProvider.activeItems.firstWhere(
      (item) => item.id == _selectedItemId,
    );

    setState(() {
      _items.add(StockOrderItemModel(
        id: _items.length + 1,
        itemId: _selectedItemId,
        itemName: item.name,
        quantity: quantity,
      ));
      _selectedItemId = null;
      _quantityController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final provider = Provider.of<StockOrderProvider>(context, listen: false);
    
    final data = {
      'items': _items.map((item) => {
        'item_id': item.itemId,
        'qty': item.quantity,
      }).toList(),
      if (_remarksController.text.trim().isNotEmpty) 'remarks': _remarksController.text.trim(),
    };

    final result = await provider.createStockOrder(data);

    setState(() {
      _isSubmitting = false;
    });

    if (!mounted) return;

    if (result['success'] == true) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock Order Created Successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Navigate to Stock Order List
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const StockOrderListScreen(),
          ),
        );
      }
    } else {
      // Handle 401 unauthorized - redirect to login
      if (result['unauthorized'] == true) {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.logout();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
        return;
      }
      
      // Show detailed error message
      final errorMessage = result['message'] ?? 'Failed to create stock order';
      final errors = result['errors'] as List<String>?;
      
      if (errors != null && errors.isNotEmpty) {
        // Show dialog for multiple validation errors
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Validation Errors'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: errors.map((error) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('• $error'),
                )).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Stock Order'),
      ),
      body: Consumer<MasterProvider>(
        builder: (context, masterProvider, child) {
          if (masterProvider.isLoading) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerLoader(),
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Remarks
                TextFormField(
                  controller: _remarksController,
                  decoration: const InputDecoration(
                    labelText: 'Remarks',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Items Section
                const Text(
                  'Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Add Item Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<int>(
                          value: _selectedItemId,
                          decoration: const InputDecoration(
                            labelText: 'Item',
                            border: OutlineInputBorder(),
                          ),
                          items: masterProvider.activeItems.isEmpty
                              ? [
                                  const DropdownMenuItem<int>(
                                    value: null,
                                    child: Text('No active items available'),
                                  ),
                                ]
                              : masterProvider.activeItems.map((item) {
                                  return DropdownMenuItem<int>(
                                    value: item.id,
                                    child: Text(item.name),
                                  );
                                }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedItemId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _quantityController,
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Add More'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Added Items List
                if (_items.isNotEmpty) ...[
                  const Text(
                    'Added Items',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(item.itemName ?? 'Item ${item.itemId}'),
                        subtitle: Text('Quantity: ${item.quantity}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeItem(index),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                // Submit Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Stock Order'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/stock_order_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/shimmer_loader.dart';

class StockOrderIssueDetailScreen extends StatefulWidget {
  final int orderId;

  const StockOrderIssueDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<StockOrderIssueDetailScreen> createState() => _StockOrderIssueDetailScreenState();
}

class _StockOrderIssueDetailScreenState extends State<StockOrderIssueDetailScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialized && mounted) {
        _isInitialized = true;
        _loadStockOrder();
      }
    });
  }

  Future<void> _loadStockOrder({bool forceReload = false}) async {
    final provider = Provider.of<StockOrderProvider>(context, listen: false);
    await provider.loadStockOrderById(widget.orderId, forceReload: forceReload);
  }

  Future<void> _handleIssue() async {
    final provider = Provider.of<StockOrderProvider>(context, listen: false);
    final result = await provider.issueStock(widget.orderId);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Stock Issued Successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    } else {
      if (result['unauthorized'] == true) {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.logout();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to issue stock'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Stock'),
      ),
      body: Consumer<StockOrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.selectedOrder == null) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerLoader(),
            );
          }

          final order = provider.selectedOrder;
          if (order == null) {
            return const Center(
              child: Text('Stock order not found'),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Header
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.orderNo ?? 'Order #${order.id}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (order.targetGodownName != null)
                                _buildInfoRow('Godown', order.targetGodownName!),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Items List
                      const Text(
                        'Items',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Item Name')),
                            DataColumn(label: Text('Quantity Required'), numeric: true),
                            DataColumn(label: Text('Available Stock'), numeric: true),
                          ],
                          rows: order.items.map((item) {
                            final availableStock = item.availableStock ?? 0.0;
                            final isLowStock = availableStock < item.quantity;
                            return DataRow(
                              cells: [
                                DataCell(Text(item.itemName ?? 'N/A')),
                                DataCell(Text(item.quantity.toStringAsFixed(0))),
                                DataCell(
                                  Text(
                                    availableStock.toStringAsFixed(0),
                                    style: TextStyle(
                                      color: isLowStock ? Colors.red : Colors.green,
                                      fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Issue Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: provider.isLoading ? null : _handleIssue,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Issue Stock'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/stock_order_provider.dart';
import '../../models/stock_order_model.dart';
import '../../widgets/shimmer_loader.dart';

class StockOrderDetailScreen extends StatefulWidget {
  final int orderId;

  const StockOrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<StockOrderDetailScreen> createState() => _StockOrderDetailScreenState();
}

class _StockOrderDetailScreenState extends State<StockOrderDetailScreen> {
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

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
        return Colors.green;
      case 'pending':
      case 'pending_approval':
        return Colors.orange;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayText(String? status) {
    if (status == null) return 'Pending';
    switch (status.toLowerCase()) {
      case 'pending_approval':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Order Details'),
      ),
      body: Consumer<StockOrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.selectedOrder == null) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerLoader(),
            );
          }

          if (provider.error != null && provider.selectedOrder == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      provider.error!,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadStockOrder(forceReload: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final order = provider.selectedOrder;
          if (order == null) {
            return const Center(
              child: Text('Stock order not found'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Header Card
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
                        _buildInfoRow('Created By', order.createdByName ?? 'N/A'),
                        if (order.createdByRole != null)
                          _buildInfoRow('Role', order.createdByRole!),
                        if (order.status != null)
                          _buildInfoRow(
                            'Status',
                            _getStatusDisplayText(order.status),
                            color: _getStatusColor(order.status),
                            isBold: true,
                          ),
                        _buildInfoRow('Total Items', order.totalItems.toString()),
                        if (order.createdAt != null)
                          _buildInfoRow(
                            'Created Date',
                            DateFormat('dd MMM yyyy HH:mm').format(order.createdAt!),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? color}) {
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
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color,
                fontSize: isBold ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


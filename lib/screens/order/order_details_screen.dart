import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/order_provider.dart';
import '../../widgets/shimmer_loader.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false)
          .loadOrderById(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.isLoading && orderProvider.selectedOrder == null) {
            return const ShimmerLoader();
          }

          if (orderProvider.error != null && 
              orderProvider.selectedOrder == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    orderProvider.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => orderProvider.loadOrderById(widget.orderId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final order = orderProvider.selectedOrder;
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          return SingleChildScrollView(
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
                          order.orderNumber ?? 'Order #${order.id}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow('Status', order.status ?? 'N/A'),
                        _buildInfoRow('Vendor', order.vendorName ?? 'N/A'),
                        _buildInfoRow('Vendor Type', order.vendorType ?? 'N/A'),
                        _buildInfoRow('Purchase Mode', order.purchaseMode ?? 'N/A'),
                        _buildInfoRow('Priority', order.priority ?? 'N/A'),
                        if (order.createdAt != null)
                          _buildInfoRow(
                            'Created',
                            DateFormat('dd MMM yyyy HH:mm').format(order.createdAt!),
                          ),
                        if (order.requiredByDate != null)
                          _buildInfoRow(
                            'Required By',
                            DateFormat('dd MMM yyyy').format(order.requiredByDate!),
                          ),
                        if (order.totalAmount != null)
                          _buildInfoRow(
                            'Total Amount',
                            '₹${order.totalAmount!.toStringAsFixed(2)}',
                            isBold: true,
                          ),
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
                ...order.items.map((item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(item.itemName ?? 'Item #${item.itemId}'),
                    subtitle: Text(
                      'Qty: ${item.qtyRequired} × ₹${item.unitPrice.toStringAsFixed(2)}',
                    ),
                    trailing: item.totalPrice != null
                        ? Text(
                            '₹${item.totalPrice!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}


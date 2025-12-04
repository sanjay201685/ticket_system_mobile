import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/stock_order_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/shimmer_loader.dart';

class StockOrderApprovalDetailScreen extends StatefulWidget {
  final int orderId;
  final String approvalType; // 'team_leader' or 'manager'

  const StockOrderApprovalDetailScreen({
    super.key,
    required this.orderId,
    required this.approvalType,
  });

  @override
  State<StockOrderApprovalDetailScreen> createState() => _StockOrderApprovalDetailScreenState();
}

class _StockOrderApprovalDetailScreenState extends State<StockOrderApprovalDetailScreen> {
  bool _isInitialized = false;
  final _reasonController = TextEditingController();

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

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadStockOrder({bool forceReload = false}) async {
    final provider = Provider.of<StockOrderProvider>(context, listen: false);
    await provider.loadStockOrderById(widget.orderId, forceReload: forceReload);
  }

  Future<void> _handleApprove() async {
    // Show remarks input dialog (optional)
    final remarks = await showDialog<String>(
      context: context,
      builder: (context) {
        final remarksController = TextEditingController();
        return AlertDialog(
          title: const Text('Approve Stock Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add remarks (optional):'),
              const SizedBox(height: 8),
              TextField(
                controller: remarksController,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  hintText: 'e.g., Approved with reduced quantities',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, remarksController.text),
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    final provider = Provider.of<StockOrderProvider>(context, listen: false);
    Map<String, dynamic> result;

    if (widget.approvalType == 'team_leader') {
      result = await provider.approveByTeamLeader(widget.orderId, remarks: remarks);
    } else {
      // Manager approval - use the same remarks dialog
      result = await provider.approveByManager(widget.orderId, remarks: remarks);
    }

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Approved Successfully'),
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
          content: Text(result['message'] ?? 'Failed to approve'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleReject() async {
    // Show reason input dialog
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Stock Order'),
        content: TextField(
          controller: _reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason (Optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _reasonController.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (reason == null && !mounted) return;

    final provider = Provider.of<StockOrderProvider>(context, listen: false);
    Map<String, dynamic> result;

    if (widget.approvalType == 'team_leader') {
      result = await provider.rejectByTeamLeader(widget.orderId, reason: reason);
    } else {
      result = await provider.rejectByManager(widget.orderId, reason: reason);
    }

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock order rejected'),
          backgroundColor: Colors.orange,
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
          content: Text(result['message'] ?? 'Failed to reject'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.approvalType == 'team_leader' ? 'Team Leader' : 'Manager'} Approval'),
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
                              _buildInfoRow('Date', order.createdAt != null
                                  ? DateFormat('dd MMM yyyy').format(order.createdAt!)
                                  : 'N/A'),
                              if (order.createdByName != null)
                                _buildInfoRow('Technician', order.createdByName!),
                              _buildInfoRow('Total Items', order.totalItems.toString()),
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
                            DataColumn(label: Text('Quantity'), numeric: true),
                          ],
                          rows: order.items.map((item) {
                            return DataRow(
                              cells: [
                                DataCell(Text(item.itemName ?? 'N/A')),
                                DataCell(Text(item.quantity.toStringAsFixed(0))),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Action Buttons
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
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: provider.isLoading ? null : _handleReject,
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: provider.isLoading ? null : _handleApprove,
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
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


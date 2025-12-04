import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/stock_order_provider.dart';
import '../../models/stock_order_model.dart';
import '../../widgets/shimmer_loader.dart';
import '../../services/auth_service.dart';

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
    final provider = Provider.of<StockOrderProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    final role = user?.role?.toLowerCase() ?? '';
    final order = provider.selectedOrder;
    
    if (order == null) return;
    
    // Show remarks input dialog (optional) - only for team leader
    String? remarks;
    if (role.contains('team') && role.contains('leader') && 
        order.status?.toLowerCase() == 'pending_team_leader') {
      remarks = await showDialog<String>(
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
    }

    if (!mounted) return;
    
    Map<String, dynamic> result;
    
    if (role.contains('team') && role.contains('leader') && 
        order.status?.toLowerCase() == 'pending_team_leader') {
      result = await provider.approveByTeamLeader(widget.orderId, remarks: remarks);
    } else if (role.contains('manager') && 
               order.status?.toLowerCase() == 'approved_by_team_leader') {
      // Show remarks input dialog (optional) - only for manager
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
      result = await provider.approveByManager(widget.orderId, remarks: remarks);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot approve this order'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
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
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    final role = user?.role?.toLowerCase() ?? '';
    final provider = Provider.of<StockOrderProvider>(context, listen: false);
    final order = provider.selectedOrder;
    
    if (order == null) return;

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

    if (reason == null || !mounted) return;

    Map<String, dynamic> result;
    
    if (role.contains('team') && role.contains('leader') && 
        order.status?.toLowerCase() == 'pending_team_leader') {
      result = await provider.rejectByTeamLeader(widget.orderId, reason: reason);
    } else if (role.contains('manager') && 
               order.status?.toLowerCase() == 'approved_by_team_leader') {
      result = await provider.rejectByManager(widget.orderId, reason: reason);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot reject this order'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
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

  bool _shouldShowApproveRejectButtons(StockOrderModel order, AuthService authService) {
    final user = authService.user;
    final role = user?.role?.toLowerCase() ?? '';
    final status = order.status?.toLowerCase() ?? '';
    
    print('🔍 StockOrderDetailScreen: Checking approve/reject buttons');
    print('   User Role: "$role" (original: "${user?.role}")');
    print('   Order Status: "$status" (original: "${order.status}")');
    
    // Team Leader can approve/reject pending_team_leader orders
    final isTeamLeader = role.contains('team') && role.contains('leader');
    final isPendingTL = status == 'pending_team_leader';
    
    print('   Is Team Leader: $isTeamLeader');
    print('   Is Pending TL: $isPendingTL');
    
    if (isTeamLeader && isPendingTL) {
      print('   ✅ Showing buttons for Team Leader');
      return true;
    }
    
    // Manager can approve/reject approved_by_team_leader orders
    final isManager = role.contains('manager');
    final isApprovedByTL = status == 'approved_by_team_leader';
    
    print('   Is Manager: $isManager');
    print('   Is Approved by TL: $isApprovedByTL');
    
    if (isManager && isApprovedByTL) {
      print('   ✅ Showing buttons for Manager');
      return true;
    }
    
    print('   ❌ Not showing buttons');
    return false;
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

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
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
                      const SizedBox(height: 16),
                      // Items List
                      if (order.items.isNotEmpty) ...[
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
                    ],
                  ),
                ),
              ),
              // Action Buttons
              Consumer<AuthService>(
                builder: (context, authService, child) {
                  if (!_shouldShowApproveRejectButtons(order, authService)) {
                    return const SizedBox.shrink();
                  }
                  
                  return Container(
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
                  );
                },
              ),
            ],
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


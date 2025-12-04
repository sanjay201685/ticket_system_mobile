import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/stock_order_provider.dart';
import '../../widgets/shimmer_loader.dart';
import '../../services/auth_service.dart';
import 'stock_order_detail_screen.dart';

class StockOrderListScreen extends StatefulWidget {
  const StockOrderListScreen({super.key});

  @override
  State<StockOrderListScreen> createState() => _StockOrderListScreenState();
}

class _StockOrderListScreenState extends State<StockOrderListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.user;
      final role = user?.role?.toLowerCase() ?? '';
      final provider = Provider.of<StockOrderProvider>(context, listen: false);
      
      // Load orders based on role
      if (role.contains('team') && role.contains('leader')) {
        provider.loadStockOrders(status: 'pending_team_leader', forceReload: true);
      } else {
        provider.loadStockOrders(forceReload: true);
      }
    });
  }


  String _getStatusDisplayText(String? status) {
    if (status == null) return 'Pending';
    switch (status.toLowerCase()) {
      case 'pending_approval':
      case 'pending_team_leader':
        return 'Pending TL';
      case 'approved_by_team_leader':
        return 'Approved by TL';
      case 'pending_store_keeper':
        return 'Pending Issue';
      case 'issued':
        return 'Issued';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'pending_team_leader':
      case 'pending_approval':
        return Colors.orange;
      case 'approved_by_team_leader':
        return Colors.blue;
      case 'pending_store_keeper':
        return Colors.purple;
      case 'issued':
        return Colors.teal;
      case 'approved':
      case 'completed':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<String?> _showRemarksDialog(BuildContext context) async {
    final remarksController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
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
      ),
    );
  }

  Future<String?> _showRejectDialog(BuildContext context) async {
    final reasonController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Stock Order'),
        content: TextField(
          controller: reasonController,
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
            onPressed: () => Navigator.pop(context, reasonController.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final authService = Provider.of<AuthService>(context, listen: false);
              final user = authService.user;
              final role = user?.role?.toLowerCase() ?? '';
              final provider = Provider.of<StockOrderProvider>(context, listen: false);
              
              // Load orders based on role
              if (role.contains('team') && role.contains('leader')) {
                provider.loadStockOrders(status: 'pending_team_leader', forceReload: true);
              } else {
                provider.loadStockOrders(forceReload: true);
              }
            },
          ),
        ],
      ),
      body: Consumer<StockOrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.stockOrders.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerLoader(),
            );
          }

          if (provider.error != null && provider.stockOrders.isEmpty) {
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
                    onPressed: () => provider.loadStockOrders(forceReload: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.stockOrders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No stock orders found',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () {
              final authService = Provider.of<AuthService>(context, listen: false);
              final user = authService.user;
              final role = user?.role?.toLowerCase() ?? '';
              
              // Load orders based on role
              if (role.contains('team') && role.contains('leader')) {
                return provider.loadStockOrders(status: 'pending_team_leader', forceReload: true);
              } else {
                return provider.loadStockOrders(forceReload: true);
              }
            },
            child: ListView.builder(
              itemCount: provider.stockOrders.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final order = provider.stockOrders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 2,
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StockOrderDetailScreen(
                                orderId: order.id,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      order.orderNo ?? 'Order #${order.id}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(order.status),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getStatusDisplayText(order.status),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (order.createdAt != null)
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Date: ${DateFormat('dd MMM yyyy').format(order.createdAt!)}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 4),
                              if (order.createdByName != null)
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Technician: ${order.createdByName}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.inventory_2, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Total Items: ${order.totalItems}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                          // Action Buttons for Team Leader
                      Consumer<AuthService>(
                        builder: (context, authService, child) {
                          final user = authService.user;
                          final role = user?.role?.toLowerCase() ?? '';
                          final status = order.status?.toLowerCase() ?? '';
                          
                          print('🔍 StockOrderListScreen: Checking buttons for order ${order.id}');
                          print('   User Role: "$role" (original: "${user?.role}")');
                          print('   Order Status: "$status" (original: "${order.status}")');
                          
                          final isTeamLeader = role.contains('team') && role.contains('leader');
                          final isPendingTL = status == 'pending_team_leader';
                          
                          print('   Is Team Leader: $isTeamLeader');
                          print('   Is Pending TL: $isPendingTL');
                          
                          // Show buttons for team leader with pending_team_leader status
                          if (isTeamLeader && isPendingTL) {
                            print('   ✅ Showing buttons for Team Leader');
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(4),
                                  bottomRight: Radius.circular(4),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    onPressed: provider.isLoading ? null : () async {
                                      final reason = await _showRejectDialog(context);
                                      if (!mounted) return;
                                      if (reason != null || reason == null) {
                                        final result = await provider.rejectByTeamLeader(order.id, reason: reason);
                                        if (mounted) {
                                          if (result['success'] == true) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Stock order rejected'),
                                                backgroundColor: Colors.orange,
                                              ),
                                            );
                                            final authService = Provider.of<AuthService>(context, listen: false);
                                            final user = authService.user;
                                            final role = user?.role?.toLowerCase() ?? '';
                                            if (role.contains('team') && role.contains('leader')) {
                                              await provider.loadStockOrders(status: 'pending_team_leader', forceReload: true);
                                            } else {
                                              await provider.loadStockOrders(forceReload: true);
                                            }
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
                                      }
                                    },
                                    icon: const Icon(Icons.close, size: 20),
                                    color: Colors.red,
                                    tooltip: 'Reject',
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: provider.isLoading ? null : () async {
                                      final remarks = await _showRemarksDialog(context);
                                      if (!mounted) return;
                                      final result = await provider.approveByTeamLeader(order.id, remarks: remarks);
                                      if (mounted) {
                                        if (result['success'] == true) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('✅ Approved Successfully'),
                                              backgroundColor: Colors.green,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                          await provider.loadStockOrders(forceReload: true);
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
                                    },
                                    icon: const Icon(Icons.check, size: 20),
                                    color: Colors.green,
                                    tooltip: 'Approve',
                                  ),
                                ],
                              ),
                            );
                          }
                          print('   ❌ Not showing buttons');
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

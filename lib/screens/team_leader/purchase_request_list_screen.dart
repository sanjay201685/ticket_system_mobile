import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/team_leader_provider.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/app_scaffold.dart';
import '../../screens/purchase/purchase_request_detail_screen.dart';

class PurchaseRequestListScreen extends StatefulWidget {
  const PurchaseRequestListScreen({super.key});

  @override
  State<PurchaseRequestListScreen> createState() => _PurchaseRequestListScreenState();
}

class _PurchaseRequestListScreenState extends State<PurchaseRequestListScreen> {
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    // Always reload when screen is opened to get latest data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when screen becomes visible again (e.g., navigating back)
    if (_hasLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = Provider.of<TeamLeaderProvider>(context, listen: false);
        // Reload if list is empty (might have been cleared)
        if (provider.purchaseRequests.isEmpty && !provider.isLoading) {
          print('🔄 List is empty, reloading purchase requests...');
          provider.loadPurchaseRequests(forceReload: true);
        }
      });
    }
  }

  void _loadData() {
    final provider = Provider.of<TeamLeaderProvider>(context, listen: false);
    provider.loadPurchaseRequests(forceReload: true);
    _hasLoaded = true;
  }

  Color _getPriorityColor(String? priority) {
    if (priority == null) return Colors.grey;
    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
        return Colors.red;
      case 'medium':
      case 'normal':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
        return Colors.green;
      case 'pending':
      case 'pending_team_leader':
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
      case 'pending_team_leader':
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
    return AppScaffold(
      title: 'Purchase Requests',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            Provider.of<TeamLeaderProvider>(context, listen: false)
                .loadPurchaseRequests(forceReload: true);
          },
        ),
      ],
      body: Consumer<TeamLeaderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.purchaseRequests.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerLoader(),
            );
          }

          if (provider.error != null && provider.purchaseRequests.isEmpty) {
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
                    onPressed: () => provider.loadPurchaseRequests(forceReload: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.purchaseRequests.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No purchase requests found',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadPurchaseRequests(forceReload: true),
            child: ListView.builder(
              itemCount: provider.purchaseRequests.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final request = provider.purchaseRequests[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 2,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PurchaseRequestDetailScreen(
                            requestId: request.id,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Leading Avatar
                          CircleAvatar(
                            backgroundColor: _getPriorityColor(request.priority),
                            radius: 24,
                            child: Text(
                              request.requestNo?.substring(0, 2).toUpperCase() ?? 
                              '#${request.id}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Main Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.requestNo ?? 'Request #${request.id}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (request.technicianName != null)
                                  Text(
                                    'Technician: ${request.technicianName}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                if (request.vendorName != null)
                                  Text(
                                    'Vendor: ${request.vendorName}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                if (request.createdAt != null)
                                  Text(
                                    'Date: ${DateFormat('dd MMM yyyy').format(request.createdAt!)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Trailing Info and Button
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(request.statusObj?['name']?.toString() ?? request.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusDisplayText(request.statusObj?['name']?.toString() ?? request.status),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Priority Badge (if exists)
                              if (request.priority != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(request.priority),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    request.priority!.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (request.priority != null) const SizedBox(height: 4),
                              if (request.totalAmount != null)
                                Text(
                                  '₹${request.totalAmount!.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.green,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Material(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(6),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PurchaseRequestDetailScreen(
                                          requestId: request.id,
                                        ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    child: Text(
                                      'View',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/team_leader_provider.dart';
import '../../api/purchase_api.dart';
import '../../models/purchase_request_model.dart';
import '../../widgets/shimmer_loader.dart';
import '../../services/auth_service.dart';

class PurchaseRequestDetailScreen extends StatefulWidget {
  final int requestId;

  const PurchaseRequestDetailScreen({
    super.key,
    required this.requestId,
  });

  @override
  State<PurchaseRequestDetailScreen> createState() => _PurchaseRequestDetailScreenState();
}

class _PurchaseRequestDetailScreenState extends State<PurchaseRequestDetailScreen> {
  final _rejectReasonController = TextEditingController();
  PurchaseRequestModel? _request;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false; // Track if initial load has been attempted
  int? _currentLoadingId; // Track which request ID is currently being loaded

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure widget is fully built before loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialized && mounted && _currentLoadingId == null) {
        _isInitialized = true;
        _loadPurchaseRequest();
      }
    });
  }

  @override
  void dispose() {
    _rejectReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadPurchaseRequest({bool forceReload = false}) async {
    // Prevent multiple simultaneous loads of the same request
    if (_isLoading && _currentLoadingId == widget.requestId && !forceReload) {
      print('⚠️ Already loading request ${widget.requestId}, skipping...');
      return;
    }
    
    // If already loaded the same request and not forcing reload, skip
    if (!forceReload && _request != null && _request!.id == widget.requestId) {
      print('⚠️ Request ${widget.requestId} already loaded, skipping...');
      return;
    }
    
    if (!mounted) return;
    
    // Mark that we're loading this specific request
    _currentLoadingId = widget.requestId;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      PurchaseRequestModel? request;
      
      // Try to use general API first (works for all roles)
      request = await PurchaseApi.getPurchaseRequestById(widget.requestId);
      
      // If general API fails and user can approve, try team leader API
      if (request == null) {
        final authService = Provider.of<AuthService>(context, listen: false);
        if (authService.user?.canApprovePurchaseRequests == true) {
          try {
            final teamLeaderProvider = Provider.of<TeamLeaderProvider>(context, listen: false);
            await teamLeaderProvider.loadPurchaseRequestById(widget.requestId, forceReload: forceReload);
            request = teamLeaderProvider.selectedRequest;
            if (request == null && teamLeaderProvider.error != null) {
              _error = teamLeaderProvider.error;
            }
          } catch (e) {
            print('⚠️ Team leader API also failed: $e');
          }
        }
      }
      
      if (!mounted) return;
      
      if (request != null) {
        setState(() {
          _request = request;
          _isLoading = false;
          _error = null;
          _currentLoadingId = null; // Clear loading ID
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = _error ?? 'Purchase request not found';
          _currentLoadingId = null; // Clear loading ID
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error in _loadPurchaseRequest: $e');
      print('❌ Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load purchase request: ${e.toString()}';
          _currentLoadingId = null; // Clear loading ID
        });
      }
    }
  }

  Future<void> _handleApprove() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.user?.canApprovePurchaseRequests != true) return;
    
    final provider = Provider.of<TeamLeaderProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    final result = await provider.approvePurchaseRequest(widget.requestId);
    
    setState(() {
      _isLoading = false;
    });
    
    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Purchase request approved successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Reload the request to get updated status
      await _loadPurchaseRequest(forceReload: true);
      
      // Navigate back to list if needed
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to approve purchase request'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleReject() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.user?.canApprovePurchaseRequests != true) return;
    
    // Show reason input dialog
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Purchase Request'),
        content: TextField(
          controller: _rejectReasonController,
          decoration: const InputDecoration(
            labelText: 'Rejection Reason',
            hintText: 'Please provide a reason for rejection',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _rejectReasonController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_rejectReasonController.text.trim().isNotEmpty) {
                Navigator.pop(context, _rejectReasonController.text.trim());
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a rejection reason'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    final provider = Provider.of<TeamLeaderProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    final result = await provider.rejectPurchaseRequest(widget.requestId, reason);
    
    setState(() {
      _isLoading = false;
    });
    
    if (!mounted) return;

    if (result['success'] == true) {
      _rejectReasonController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Purchase request rejected successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Reload the request to get updated status
      await _loadPurchaseRequest(forceReload: true);
      
      // Navigate back to list if needed
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to reject purchase request'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Request Details'),
      ),
      body: _isLoading && _request == null
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerLoader(),
            )
          : _error != null && _request == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _error!,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _loadPurchaseRequest(forceReload: true);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _request == null
                  ? const Center(
                      child: Text('Purchase request not found'),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Request Header Card
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _request!.requestNo ?? 'Request #${_request!.id}',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        _buildInfoRow('Vendor', _request!.vendorName ?? 'N/A'),
                                        _buildInfoRow('Vendor Type', _request!.vendorType ?? 'N/A'),
                                        _buildInfoRow('Priority', _request!.priority ?? 'N/A'),
                                        _buildInfoRow('Payment Mode', _request!.paymentMode ?? 'N/A'),
                                        _buildInfoRow('Created By', _request!.createdByName ?? _request!.technicianName ?? 'N/A'),
                                        if (_request!.createdAt != null)
                                          _buildInfoRow(
                                            'Created Date',
                                            DateFormat('dd MMM yyyy HH:mm').format(_request!.createdAt!),
                                          ),
                                        if (_request!.requiredByDate != null)
                                          _buildInfoRow(
                                            'Required By',
                                            DateFormat('dd MMM yyyy').format(_request!.requiredByDate!),
                                          ),
                                        if (_request!.status != null)
                                          _buildInfoRow(
                                            'Status',
                                            _request!.status!,
                                            color: _getStatusColor(_request!.status),
                                            isBold: true,
                                          ),
                                        if (_request!.totalAmount != null)
                                          _buildInfoRow(
                                            'Estimated Amount',
                                            '₹${_request!.totalAmount!.toStringAsFixed(2)}',
                                            isBold: true,
                                            color: Colors.green,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Items Table
                                const Text(
                                  'Items',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Card(
                                  child: _request!.items.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Center(
                                            child: Text('No items found'),
                                          ),
                                        )
                                      : SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: DataTable(
                                            columns: const [
                                              DataColumn(label: Text('Item')),
                                              DataColumn(label: Text('Qty')),
                                              DataColumn(label: Text('Unit Price')),
                                              DataColumn(label: Text('GST %')),
                                              DataColumn(label: Text('Total')),
                                            ],
                                            rows: _request!.items.map((item) {
                                              final itemTotal = item.totalPrice ?? 
                                                  (item.qtyRequired * item.unitPrice);
                                              return DataRow(
                                                cells: [
                                                  DataCell(Text(item.itemName ?? 'Item #${item.itemId}')),
                                                  DataCell(Text(item.qtyRequired.toStringAsFixed(2))),
                                                  DataCell(Text('₹${item.unitPrice.toStringAsFixed(2)}')),
                                                  DataCell(Text(
                                                    item.gstPercent != null 
                                                        ? '${item.gstPercent!.toStringAsFixed(2)}%'
                                                        : '0%',
                                                  )),
                                                  DataCell(Text(
                                                    '₹${itemTotal.toStringAsFixed(2)}',
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                  )),
                                                ],
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Action Buttons (only for team leaders, managers, cashiers)
                        Consumer<AuthService>(
                          builder: (context, authService, child) {
                            // Debug logging
                            final user = authService.user;
                            final userRole = user?.role;
                            print('🔍 PurchaseRequestDetailScreen: Checking approve permissions');
                            print('   User: ${user?.name ?? "null"}');
                            print('   Role: "$userRole"');
                            if (userRole != null) {
                              print('   Role type: ${userRole.runtimeType}');
                            }
                            
                            final canApprove = user?.canApprovePurchaseRequests == true;
                            print('   canApprovePurchaseRequests: $canApprove');
                            
                            final isPending = _request!.status?.toLowerCase() == 'pending' || 
                                            _request!.status?.toLowerCase() == 'pending_team_leader' ||
                                            _request!.status == null;
                            print('   Request status: "${_request!.status ?? "null"}"');
                            print('   isPending: $isPending');
                            
                            if (!canApprove || !isPending) {
                              print('   ❌ Buttons hidden - canApprove: $canApprove, isPending: $isPending');
                              return const SizedBox.shrink();
                            }
                            
                            print('   ✅ Showing approve/reject buttons');
                            
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(0, -3),
                                  ),
                                ],
                              ),
                              child: SafeArea(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _isLoading ? null : _handleApprove,
                                        icon: const Icon(Icons.check_circle),
                                        label: const Text('Approve'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _isLoading ? null : _handleReject,
                                        icon: const Icon(Icons.cancel),
                                        label: const Text('Reject'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
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


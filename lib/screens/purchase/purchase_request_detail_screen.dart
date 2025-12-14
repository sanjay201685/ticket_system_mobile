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
        
        // Clear only selected request cache (preserve list cache)
        print('🧹 Clearing selected request cache for fresh data...');
        
        // Clear local state
        _request = null;
        _currentLoadingId = null;
        
        // Clear only selected request, not the entire cache (preserves list)
        try {
          final teamLeaderProvider = Provider.of<TeamLeaderProvider>(context, listen: false);
          teamLeaderProvider.clearSelectedRequest();
          print('✅ Selected request cache cleared (list preserved)');
        } catch (e) {
          print('⚠️ Could not clear selected request cache: $e');
        }
        
        // Force reload to get fresh data and avoid cache issues
        _loadPurchaseRequest(forceReload: true);
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
      
      // Clear only selected request cache if forcing reload (preserve list)
      if (forceReload) {
        print('🧹 Force reload requested - clearing selected request cache...');
        try {
          final teamLeaderProvider = Provider.of<TeamLeaderProvider>(context, listen: false);
          teamLeaderProvider.clearSelectedRequest();
          print('✅ Selected request cache cleared for force reload');
        } catch (e) {
          print('⚠️ Could not clear selected request cache: $e');
        }
      }
      
      // Try to use general API first (works for all roles)
      request = await PurchaseApi.getPurchaseRequestById(widget.requestId);
      
      // If general API fails and user can approve, try team leader API
      if (request == null) {
        final authService = Provider.of<AuthService>(context, listen: false);
        if (authService.user?.canApprovePurchaseRequests == true) {
          try {
            final teamLeaderProvider = Provider.of<TeamLeaderProvider>(context, listen: false);
            await teamLeaderProvider.loadPurchaseRequestById(widget.requestId, forceReload: true);
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
        // Debug: Log the technician name and created by name values
        print('📋 Purchase Request Loaded:');
        print('   ID: ${request.id}');
        print('   technicianName: "${request.technicianName}"');
        print('   createdByName: "${request.createdByName}"');
        print('   createdById: ${request.createdById}');
        
        // Check current user role for debugging
        final authService = Provider.of<AuthService>(context, listen: false);
        final user = authService.user;
        final userRole = user?.role?.toLowerCase().trim() ?? '';
        print('   Current User Role: "$userRole"');
        if (userRole.contains('team') && userRole.contains('leader')) {
          print('   ⚠️ Team Leader detected - will use special name detection logic');
        }
        
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
                                        _buildInfoRow('Created By', _getCreatedByDisplay()),
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
                            final userRoleStr = user?.role?.toString().toLowerCase() ?? '';
                            print('🔍 PurchaseRequestDetailScreen: Checking approve permissions');
                            print('   User: ${user?.name ?? "null"}');
                            print('   Role: "$userRoleStr"');
                            
                            final canApprove = user?.canApprovePurchaseRequests == true;
                            print('   canApprovePurchaseRequests: $canApprove');
                            
                            // Get status key from status object or fallback to status string
                            final statusKey = _request!.statusObj?['key']?.toString()?.toLowerCase() ?? 
                                            _request!.status?.toLowerCase();
                            
                            // Team Leader: show approve button only when status.key == 'pending_team_leader'
                            // Manager: show approve button only when status.key == 'pending_manager'
                            final shouldShowApprove = canApprove && (
                              (userRoleStr.contains('team') && userRoleStr.contains('leader') && statusKey == 'pending_team_leader') ||
                              (userRoleStr.contains('manager') && statusKey == 'pending_manager')
                            );
                            
                            print('   Request status key: "$statusKey"');
                            print('   User role: "$userRoleStr"');
                            print('   shouldShowApprove: $shouldShowApprove');
                            
                            if (!shouldShowApprove) {
                              print('   ❌ Buttons hidden - canApprove: $canApprove, shouldShowApprove: $shouldShowApprove');
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

  /// Get the display value for "Created By" field
  /// For team leaders, managers, and cashiers: show technician name instead of role
  String _getCreatedByDisplay() {
    if (_request == null) return 'N/A';
    
    // Check if current user is team leader, manager, or cashier
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    final userRole = user?.role?.toLowerCase().trim() ?? '';
    
    //final isTeamLeader = (userRole.contains('team') && userRole.contains('leader')) || 
    //                     userRole.contains('teamleader') ||
    final isTeamLeader = userRole.contains('team_leader');
    final isManager = userRole.contains('manager');
    final isCashier = userRole.contains('cashier');
    
    // Normalize string by removing spaces, underscores, hyphens for comparison
    String normalizeString(String? value) {
      if (value == null || value.isEmpty) return '';
      return value.toLowerCase().trim().replaceAll(RegExp(r'[\s_\-]'), '');
    }
    
    // Check if value is a role (normalized comparison)
    bool isRole(String? value) {
      if (value == null || value.isEmpty) return false;
      
      final normalized = normalizeString(value);
      final rolePatterns = [
        'technician',
        'teamleader',
        'team_leader',
        'manager',
        'cashier',
        'admin',
        'administrator',
      ];
      
      // Check if normalized string matches any role pattern
      for (var role in rolePatterns) {
        if (normalized == role) {
          return true;
        }
      }
      
      // Also check if the original value (case-insensitive) matches common role formats
      final lower = value.toLowerCase().trim();
      final exactRoles = [
        'technician',
        'team leader',
        'team_leader',
        'teamleader',
        'team-leader',
        'team leader',
        'manager',
        'cashier',
        'admin',
        'administrator',
      ];
      
      return exactRoles.contains(lower);
    }
    
    // Debug logging
    print('🔍 _getCreatedByDisplay:');
    print('   User role: "$userRole"');
    print('   Is Team Leader: $isTeamLeader, Is Manager: $isManager, Is Cashier: $isCashier');
    print('   technicianName: "${_request!.technicianName}"');
    print('   createdByName: "${_request!.createdByName}"');
    
    // For team leaders, managers, and cashiers: use technicianName if it's not a role
    if (isTeamLeader || isManager || isCashier) {
      // Prefer technicianName - it should contain the actual name
      if (_request!.technicianName != null && _request!.technicianName!.isNotEmpty) {
        if (!isRole(_request!.technicianName)) {
          print('   ✅ Using technicianName: "${_request!.technicianName}"');
          return _request!.technicianName!;
        } else {
          print('   ⚠️ technicianName is a role: "${_request!.technicianName}" - REJECTED');
        }
      }
      
      // Fallback to createdByName if it's not a role
      if (_request!.createdByName != null && _request!.createdByName!.isNotEmpty) {
        if (!isRole(_request!.createdByName)) {
          print('   ✅ Using createdByName: "${_request!.createdByName}"');
          return _request!.createdByName!;
        } else {
          print('   ⚠️ createdByName is a role: "${_request!.createdByName}" - REJECTED');
        }
      }
      
      // If both are roles or empty, return N/A
      print('   ❌ Both fields are roles or empty - returning N/A');
      return 'N/A';
    }
    
    // For other users (technicians), use the default logic
    return _request!.createdByName ?? _request!.technicianName ?? 'N/A';
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


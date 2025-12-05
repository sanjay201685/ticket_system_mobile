import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/stock_order_provider.dart';
import '../../../providers/master_provider.dart';
import '../../../services/auth_service.dart';
import '../../../models/dropdown_model.dart';

class IssueStockScreen extends StatefulWidget {
  final int stockOrderId;
  final String orderNo;

  const IssueStockScreen({
    super.key,
    required this.stockOrderId,
    required this.orderNo,
  });

  @override
  State<IssueStockScreen> createState() => _IssueStockScreenState();
}

class _IssueStockScreenState extends State<IssueStockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _remarksController = TextEditingController();
  
  int? _selectedGodownId;
  int? _selectedTechnicianId;
  bool _isLoading = false;
  bool _isLoadingData = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialized && mounted) {
        _isInitialized = true;
        _loadDropdownData();
      }
    });
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownData() async {
    final masterProvider = Provider.of<MasterProvider>(context, listen: false);
    final stockOrderProvider = Provider.of<StockOrderProvider>(context, listen: false);
    
    // Load stock order to check status
    await stockOrderProvider.loadStockOrderById(widget.stockOrderId, forceReload: true);
    
    // Load godowns and technicians if not already loaded
    if (masterProvider.godowns.isEmpty || masterProvider.technicians.isEmpty) {
      setState(() {
        _isLoadingData = true;
      });
      await masterProvider.loadAllMasterData();
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _handleIssueStock() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedGodownId == null || _selectedTechnicianId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Godown and Technician'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<StockOrderProvider>(context, listen: false);
    final result = await provider.issueStock(
      widget.stockOrderId,
      godownId: _selectedGodownId!,
      forTechnicianId: _selectedTechnicianId!,
      remarks: _remarksController.text.trim().isNotEmpty 
          ? _remarksController.text.trim() 
          : null,
    );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? '✅ Stock Issued Successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Navigate back to list screen
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
    final masterProvider = Provider.of<MasterProvider>(context);
    final stockOrderProvider = Provider.of<StockOrderProvider>(context);
    final authService = Provider.of<AuthService>(context);
    
    // Check role and status visibility
    final userRole = authService.user?.role?.toString().toLowerCase() ?? '';
    final isStoreKeeper = userRole.contains('store') || userRole.contains('store_keeper');
    
    // Get stock order status
    final stockOrder = stockOrderProvider.selectedOrder;
    final orderStatus = stockOrder?.status?.toLowerCase() ?? '';
    final isPendingStoreKeeper = orderStatus == 'pending_store_keeper';
    
    // Show loading if master data is loading or stock order is loading
    if (masterProvider.isLoading || _isLoadingData || (stockOrder == null && stockOrderProvider.isLoading)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Issue Stock'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Show error if stock order not found
    if (stockOrder == null && !stockOrderProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Issue Stock'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Stock order not found'),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Stock'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order No (Readonly)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order No',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.orderNo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Godown Dropdown
              DropdownButtonFormField<int>(
                value: _selectedGodownId,
                decoration: InputDecoration(
                  labelText: 'Select Godown *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.warehouse),
                  errorText: masterProvider.godowns.isEmpty 
                      ? 'No godowns available. Please contact administrator.' 
                      : null,
                ),
                items: masterProvider.godowns.isEmpty
                    ? [
                        const DropdownMenuItem<int>(
                          value: null,
                          enabled: false,
                          child: Text('No godowns available'),
                        ),
                      ]
                    : masterProvider.godowns.map((godown) {
                        return DropdownMenuItem<int>(
                          value: godown.id,
                          child: Text(godown.name),
                        );
                      }).toList(),
                onChanged: masterProvider.godowns.isEmpty
                    ? null
                    : (value) {
                        setState(() {
                          _selectedGodownId = value;
                        });
                      },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a godown';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Technician Dropdown
              DropdownButtonFormField<int>(
                value: _selectedTechnicianId,
                decoration: InputDecoration(
                  labelText: 'Select Technician *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                  errorText: masterProvider.technicians.isEmpty 
                      ? 'No technicians available. Please contact administrator.' 
                      : null,
                ),
                items: masterProvider.technicians.isEmpty
                    ? [
                        const DropdownMenuItem<int>(
                          value: null,
                          enabled: false,
                          child: Text('No technicians available'),
                        ),
                      ]
                    : masterProvider.technicians.map((technician) {
                        return DropdownMenuItem<int>(
                          value: technician.id,
                          child: Text(technician.name),
                        );
                      }).toList(),
                onChanged: masterProvider.technicians.isEmpty
                    ? null
                    : (value) {
                        setState(() {
                          _selectedTechnicianId = value;
                        });
                      },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a technician';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Remarks TextArea
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  hintText: 'Enter remarks (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 32),
              
              // Issue Stock Button - Only show if Store Keeper AND status is pending_store_keeper
              if (isStoreKeeper && isPendingStoreKeeper)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleIssueStock,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text(_isLoading ? 'Issuing Stock...' : 'Issue Stock'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: Colors.grey,
                    ),
                  ),
                ),
              
              // Warning messages
              if (!isStoreKeeper)
                const Card(
                  color: Colors.orange,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Only Store Keeper can issue stock',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              if (isStoreKeeper && !isPendingStoreKeeper)
                Card(
                  color: Colors.red,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This order is not pending for issue. Current status: ${stockOrder?.status ?? "Unknown"}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


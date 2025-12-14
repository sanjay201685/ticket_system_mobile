import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/wallet_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/app_scaffold.dart';
import '../../models/wallet_transaction_model.dart';

class WalletTransactionScreen extends StatefulWidget {
  final int? userId; // Optional: if null, uses authenticated user

  const WalletTransactionScreen({
    super.key,
    this.userId,
  });

  @override
  State<WalletTransactionScreen> createState() => _WalletTransactionScreenState();
}

class _WalletTransactionScreenState extends State<WalletTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _referenceIdController = TextEditingController();

  String? _selectedType; // 'credit' or 'debit'
  String? _selectedReferenceType;
  int? _selectedUserId;
  String? _selectedTypeFilter;
  String? _selectedStatusFilter;
  bool _isCreatingTransaction = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _referenceIdController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final user = authService.user;

    // Determine user ID to use
    final targetUserId = widget.userId ?? user?.id ?? 0;
    _selectedUserId = targetUserId;

    // Load balance and transactions
    await Future.wait([
      walletProvider.loadBalance(targetUserId, forceReload: true),
      walletProvider.loadTransactions(
        userId: targetUserId,
        forceReload: true,
      ),
    ]);
  }

  bool _canCreditWallet() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    if (user == null) return false;

    final role = user.role?.toLowerCase() ?? '';
    // Only Admin and Manager can credit wallets
    return role.contains('admin') || role.contains('manager');
  }

  bool _canDebitWallet() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    if (user == null) return false;

    final role = user.role?.toLowerCase() ?? '';
    final targetUserId = widget.userId ?? user.id ?? 0;

    // Admin can debit any wallet
    if (role.contains('admin')) return true;

    // Technicians can only debit their own wallet
    if (role.contains('technician')) {
      return targetUserId == user.id;
    }

    // Managers can debit any wallet
    if (role.contains('manager')) return true;

    return false;
  }

  Future<void> _showCreateTransactionDialog() async {
    // Check permissions
    if (_selectedType == 'credit' && !_canCreditWallet()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only Admin and Manager can credit wallets'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedType == 'debit' && !_canDebitWallet()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to debit this wallet'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Reset form
    _amountController.clear();
    _notesController.clear();
    _referenceIdController.clear();
    _selectedReferenceType = null;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CreateTransactionDialog(
        formKey: _formKey,
        amountController: _amountController,
        notesController: _notesController,
        referenceIdController: _referenceIdController,
        selectedType: _selectedType!,
        selectedReferenceType: _selectedReferenceType,
        onReferenceTypeChanged: (value) {
          setState(() {
            _selectedReferenceType = value;
          });
        },
        balance: Provider.of<WalletProvider>(context, listen: false).balance,
      ),
    );

    if (result != null && result['success'] == true) {
      // Reload data
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Transaction created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (result != null && result['success'] == false) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to create transaction'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _applyFilters() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final targetUserId = widget.userId ?? _selectedUserId;

    await walletProvider.loadTransactions(
      userId: targetUserId,
      type: _selectedTypeFilter,
      status: _selectedStatusFilter,
      forceReload: true,
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter Transactions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Type filter
              DropdownButtonFormField<String>(
                value: _selectedTypeFilter,
                decoration: const InputDecoration(
                  labelText: 'Transaction Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'credit', child: Text('Credit')),
                  DropdownMenuItem(value: 'debit', child: Text('Debit')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedTypeFilter = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Status filter
              DropdownButtonFormField<String>(
                value: _selectedStatusFilter,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'paid', child: Text('Paid')),
                  DropdownMenuItem(value: 'failed', child: Text('Failed')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatusFilter = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedTypeFilter = null;
                  _selectedStatusFilter = null;
                });
              },
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _applyFilters();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTransactionTypeColor(String type) {
    return type.toLowerCase() == 'credit' ? Colors.green : Colors.red;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    final targetUserId = widget.userId ?? user?.id ?? 0;

    return AppScaffold(
      title: 'Wallet Transactions',
      actions: [
        // Filter button
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterDialog,
          tooltip: 'Filter transactions',
        ),
        // Create transaction button
        if (_canCreditWallet() || _canDebitWallet())
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            tooltip: 'Create transaction',
            onSelected: (value) {
              setState(() {
                _selectedType = value;
              });
              _showCreateTransactionDialog();
            },
            itemBuilder: (context) => [
              if (_canCreditWallet())
                const PopupMenuItem(
                  value: 'credit',
                  child: Row(
                    children: [
                      Icon(Icons.add_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Credit Wallet'),
                    ],
                  ),
                ),
              if (_canDebitWallet())
                const PopupMenuItem(
                  value: 'debit',
                  child: Row(
                    children: [
                      Icon(Icons.remove_circle, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Debit Wallet'),
                    ],
                  ),
                ),
            ],
          ),
      ],
      body: Consumer<WalletProvider>(
        builder: (context, provider, child) {
          // Show balance card at top
          return Column(
            children: [
              // Balance Card
              if (provider.balance != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Wallet Balance',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.balance!.formattedBalance,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (provider.isLoadingBalance)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              else if (provider.isLoadingBalance)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),

              // Active filters
              if (_selectedTypeFilter != null || _selectedStatusFilter != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Text(
                        'Filters: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (_selectedTypeFilter != null)
                        Chip(
                          label: Text('Type: ${_selectedTypeFilter}'),
                          onDeleted: () {
                            setState(() {
                              _selectedTypeFilter = null;
                            });
                            _applyFilters();
                          },
                        ),
                      if (_selectedStatusFilter != null) ...[
                        const SizedBox(width: 8),
                        Chip(
                          label: Text('Status: ${_selectedStatusFilter}'),
                          onDeleted: () {
                            setState(() {
                              _selectedStatusFilter = null;
                            });
                            _applyFilters();
                          },
                        ),
                      ],
                    ],
                  ),
                ),

              // Transactions List
              Expanded(
                child: _buildTransactionsList(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTransactionsList(WalletProvider provider) {
    if (provider.isLoading && provider.transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: ShimmerLoader(),
      );
    }

    if (provider.error != null && provider.transactions.isEmpty) {
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
              onPressed: () => _loadData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No transactions found',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadData(),
      child: ListView.builder(
        itemCount: provider.transactions.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final transaction = provider.transactions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Transaction type and amount
                      Row(
                        children: [
                          Icon(
                            transaction.isCredit
                                ? Icons.add_circle
                                : Icons.remove_circle,
                            color: _getTransactionTypeColor(transaction.transactionType),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            transaction.formattedAmount,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _getTransactionTypeColor(transaction.transactionType),
                            ),
                          ),
                        ],
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(transaction.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(transaction.status),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          transaction.status.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(transaction.status),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Details
                  if (transaction.referenceType != null)
                    Row(
                      children: [
                        const Icon(Icons.link, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${transaction.referenceType}${transaction.referenceId != null ? ' #${transaction.referenceId}' : ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      transaction.notes!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Date
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(transaction.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Dialog for creating transactions
class _CreateTransactionDialog extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController amountController;
  final TextEditingController notesController;
  final TextEditingController referenceIdController;
  final String selectedType;
  final String? selectedReferenceType;
  final Function(String?) onReferenceTypeChanged;
  final WalletBalance? balance;

  const _CreateTransactionDialog({
    required this.formKey,
    required this.amountController,
    required this.notesController,
    required this.referenceIdController,
    required this.selectedType,
    required this.selectedReferenceType,
    required this.onReferenceTypeChanged,
    required this.balance,
  });

  @override
  State<_CreateTransactionDialog> createState() => _CreateTransactionDialogState();
}

class _CreateTransactionDialogState extends State<_CreateTransactionDialog> {
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!widget.formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      final user = authService.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final amount = double.tryParse(widget.amountController.text);
      if (amount == null || amount < 0.01) {
        throw Exception('Invalid amount');
      }

      // Check balance for debit
      if (widget.selectedType == 'debit' && widget.balance != null) {
        if (amount > widget.balance!.balance) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Insufficient wallet balance'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _isSubmitting = false;
          });
          return;
        }
      }

      int? referenceId;
      if (widget.referenceIdController.text.isNotEmpty) {
        referenceId = int.tryParse(widget.referenceIdController.text);
      }

      final result = await walletProvider.createTransaction(
        userId: user.id!,
        transactionType: widget.selectedType,
        amount: amount,
        referenceType: widget.selectedReferenceType,
        referenceId: referenceId,
        notes: widget.notesController.text.isEmpty
            ? null
            : widget.notesController.text,
      );

      if (mounted) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.selectedType.toUpperCase()} Wallet'),
      content: SingleChildScrollView(
        child: Form(
          key: widget.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount field
              TextFormField(
                controller: widget.amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount *',
                  hintText: '0.00',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Amount is required';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount < 0.01) {
                    return 'Amount must be at least 0.01';
                  }
                  if (widget.selectedType == 'debit' &&
                      widget.balance != null &&
                      amount > widget.balance!.balance) {
                    return 'Insufficient balance';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Reference type
              DropdownButtonFormField<String>(
                value: widget.selectedReferenceType,
                decoration: const InputDecoration(
                  labelText: 'Reference Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('None')),
                  DropdownMenuItem(value: 'manual', child: Text('Manual')),
                  DropdownMenuItem(
                      value: 'purchase_request', child: Text('Purchase Request')),
                  DropdownMenuItem(value: 'refund', child: Text('Refund')),
                ],
                onChanged: widget.onReferenceTypeChanged,
              ),
              const SizedBox(height: 16),
              // Reference ID (if reference type is selected)
              if (widget.selectedReferenceType != null &&
                  widget.selectedReferenceType != 'manual')
                TextFormField(
                  controller: widget.referenceIdController,
                  decoration: const InputDecoration(
                    labelText: 'Reference ID',
                    hintText: 'e.g., 123',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (widget.selectedReferenceType != null &&
                        widget.selectedReferenceType != 'manual' &&
                        value != null &&
                        value.isNotEmpty) {
                      final id = int.tryParse(value);
                      if (id == null) {
                        return 'Invalid reference ID';
                      }
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),
              // Notes
              TextFormField(
                controller: widget.notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Additional notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              // Balance info for debit
              if (widget.selectedType == 'debit' && widget.balance != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Available Balance: ${widget.balance!.formattedBalance}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Create ${widget.selectedType.toUpperCase()}'),
        ),
      ],
    );
  }
}

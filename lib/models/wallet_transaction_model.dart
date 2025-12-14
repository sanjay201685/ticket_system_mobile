class WalletTransaction {
  final int id;
  final String transactionType; // 'credit' or 'debit'
  final double amount;
  final String formattedAmount; // e.g., "₹500.00"
  final String? referenceType; // e.g., "manual", "purchase_request"
  final int? referenceId;
  final String status; // 'pending', 'paid', 'failed'
  final String? notes;
  final int? processedBy; // User ID who processed the transaction
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.transactionType,
    required this.amount,
    required this.formattedAmount,
    this.referenceType,
    this.referenceId,
    required this.status,
    this.notes,
    this.processedBy,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    try {
      // Parse amount - handle both string and number
      double amountValue;
      if (json['amount'] is String) {
        amountValue = double.tryParse(json['amount']) ?? 0.0;
      } else {
        amountValue = (json['amount'] as num?)?.toDouble() ?? 0.0;
      }

      // Parse date
      DateTime parseDate(String? dateStr) {
        if (dateStr == null || dateStr.isEmpty) {
          return DateTime.now();
        }
        try {
          return DateTime.parse(dateStr);
        } catch (e) {
          return DateTime.now();
        }
      }

      return WalletTransaction(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        transactionType: json['transaction_type']?.toString() ?? '',
        amount: amountValue,
        formattedAmount: json['formatted_amount']?.toString() ?? '₹${amountValue.toStringAsFixed(2)}',
        referenceType: json['reference_type']?.toString(),
        referenceId: json['reference_id'] is int 
            ? json['reference_id'] 
            : json['reference_id'] != null 
                ? int.tryParse(json['reference_id'].toString()) 
                : null,
        status: json['status']?.toString() ?? 'pending',
        notes: json['notes']?.toString(),
        processedBy: json['processed_by'] is int 
            ? json['processed_by'] 
            : json['processed_by'] != null 
                ? int.tryParse(json['processed_by'].toString()) 
                : null,
        createdAt: parseDate(json['created_at']?.toString()),
      );
    } catch (e) {
      throw Exception('Failed to parse WalletTransaction: $e. JSON: $json');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_type': transactionType,
      'amount': amount,
      'formatted_amount': formattedAmount,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'status': status,
      'notes': notes,
      'processed_by': processedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Check if transaction is credit
  bool get isCredit => transactionType.toLowerCase() == 'credit';

  /// Check if transaction is debit
  bool get isDebit => transactionType.toLowerCase() == 'debit';

  /// Check if transaction is completed
  bool get isPaid => status.toLowerCase() == 'paid';

  /// Check if transaction is pending
  bool get isPending => status.toLowerCase() == 'pending';

  /// Check if transaction failed
  bool get isFailed => status.toLowerCase() == 'failed';
}

class WalletBalance {
  final int userId;
  final double balance;
  final String formattedBalance;
  final String currency;

  WalletBalance({
    required this.userId,
    required this.balance,
    required this.formattedBalance,
    required this.currency,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    double balanceValue;
    if (json['balance'] is String) {
      balanceValue = double.tryParse(json['balance']) ?? 0.0;
    } else {
      balanceValue = (json['balance'] as num?)?.toDouble() ?? 0.0;
    }

    return WalletBalance(
      userId: json['user_id'] is int 
          ? json['user_id'] 
          : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      balance: balanceValue,
      formattedBalance: json['formatted_balance']?.toString() ?? '₹${balanceValue.toStringAsFixed(2)}',
      currency: json['currency']?.toString() ?? 'INR',
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/payment_service.dart';
import '../services/auth_service.dart';
import '../services/error_service.dart';
import '../widgets/error_message.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/custom_button.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen>
    with TickerProviderStateMixin {
  final PaymentService _paymentService = PaymentService();
  final AuthService _authService = AuthService();
  final ErrorService _errorService = ErrorService();

  List<PaymentTransaction> _transactions = [];
  List<PaymentTransaction> _filteredTransactions = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  PaymentStatus? _selectedStatus;
  String? _selectedPaymentMethod;
  DateTime? _startDate;
  DateTime? _endDate;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _loadPaymentHistory();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = await _authService.getCurrentUserModel();
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final transactions = await _paymentService.getPaymentHistory(
        userId: currentUser.id,
        limit: 50,
      );

      setState(() {
        _transactions = transactions;
        _filteredTransactions = transactions;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      _errorService.logError('Failed to load payment history', e);
      setState(() {
        _error = _errorService.getUserFriendlyErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredTransactions = _transactions.where((transaction) {
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final matchesSearch = transaction.description
                  .toLowerCase()
                  .contains(query) ||
              transaction.id.toLowerCase().contains(query) ||
              transaction.transactionId?.toLowerCase().contains(query) == true;
          if (!matchesSearch) return false;
        }

        // Status filter
        if (_selectedStatus != null && transaction.status != _selectedStatus) {
          return false;
        }

        // Payment method filter
        if (_selectedPaymentMethod != null &&
            transaction.paymentMethod.name != _selectedPaymentMethod) {
          return false;
        }

        // Date range filter
        if (_startDate != null && transaction.createdAt.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null && transaction.createdAt.isAfter(_endDate!)) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedStatus = null;
      _selectedPaymentMethod = null;
      _startDate = null;
      _endDate = null;
      _filteredTransactions = _transactions;
    });
  }

  Future<void> _requestRefund(PaymentTransaction transaction) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for the refund:'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'e.g., Service not received, Double payment',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'Refund requested'),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        final success = await _paymentService.requestRefund(
          transactionId: transaction.id,
          reason: reason,
        );

        if (success) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Refund request submitted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadPaymentHistory(); // Refresh the list
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit refund request'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.processing:
        return Colors.orange;
      case PaymentStatus.pending:
        return Colors.blue;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
      case PaymentStatus.refunded:
        return Colors.purple;
    }
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mtnMobileMoney:
      case PaymentMethod.airtelMoney:
      case PaymentMethod.mpesa:
        return Icons.phone_android;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
    }
  }

  Color _getPaymentMethodColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mtnMobileMoney:
        return Colors.orange;
      case PaymentMethod.airtelMoney:
        return Colors.red;
      case PaymentMethod.mpesa:
        return Colors.green;
      case PaymentMethod.card:
        return Colors.blue;
      case PaymentMethod.bankTransfer:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPaymentHistory,
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildFilterSection(),
              Expanded(
                child: _buildTransactionList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              labelText: 'Search transactions',
              hintText: 'Search by description, ID...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                        _applyFilters();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _applyFilters();
            },
          ),
          const SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All',
                  isSelected: _selectedStatus == null,
                  onTap: () {
                    setState(() {
                      _selectedStatus = null;
                    });
                    _applyFilters();
                  },
                ),
                ...PaymentStatus.values.map((status) => _buildFilterChip(
                      label: status.name.toUpperCase(),
                      isSelected: _selectedStatus == status,
                      color: _getStatusColor(status),
                      onTap: () {
                        setState(() {
                          _selectedStatus =
                              _selectedStatus == status ? null : status;
                        });
                        _applyFilters();
                      },
                    )),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Clear All',
                  isSelected: false,
                  onTap: _clearFilters,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        backgroundColor: Colors.white,
        selectedColor: color ?? Colors.deepPurple,
        onSelected: (_) => onTap(),
        side: BorderSide(
          color:
              isSelected ? (color ?? Colors.deepPurple) : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    if (_error != null) {
      return ErrorMessage(
        error: _error,
        onRetry: _loadPaymentHistory,
      );
    }

    if (_filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _transactions.isEmpty
                  ? 'No payment history'
                  : 'No transactions found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _transactions.isEmpty
                  ? 'Your payment transactions will appear here'
                  : 'Try adjusting your filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _filteredTransactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(PaymentTransaction transaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getPaymentMethodColor(transaction.paymentMethod)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getPaymentMethodIcon(transaction.paymentMethod),
                    color: _getPaymentMethodColor(transaction.paymentMethod),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${transaction.paymentMethod.name.replaceAll('_', ' ').toUpperCase()} • ${DateFormat('MMM dd, yyyy HH:mm').format(transaction.createdAt)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${transaction.amount.toStringAsFixed(0)} ${transaction.currency}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(transaction.status)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        transaction.status.name.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(transaction.status),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (transaction.transactionId != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Transaction ID: ',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      transaction.transactionId!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (transaction.errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        transaction.errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (transaction.status == PaymentStatus.completed) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Request Refund',
                      onPressed: () => _requestRefund(transaction),
                      backgroundColor: Colors.orange.shade600,
                      textColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

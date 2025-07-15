import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sales_service.dart';
import '../models/sale_model.dart';
import '../widgets/common_widgets.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  final List<Map<String, dynamic>> _filters = [
    {'id': 'all', 'name': 'All Sales'},
    {'id': 'today', 'name': 'Today'},
    {'id': 'week', 'name': 'This Week'},
    {'id': 'month', 'name': 'This Month'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final salesService = Provider.of<SalesService>(context, listen: false);
      salesService.loadSales();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SaleModel> _getFilteredSales(List<SaleModel> sales) {
    List<SaleModel> filtered = sales;

    // Apply date filter
    switch (_selectedFilter) {
      case 'today':
        final today = DateTime.now();
        filtered = filtered.where((sale) {
          return sale.createdAt.year == today.year &&
                 sale.createdAt.month == today.month &&
                 sale.createdAt.day == today.day;
        }).toList();
        break;
      case 'week':
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        filtered = filtered.where((sale) {
          return sale.createdAt.isAfter(startOfWeek.subtract(const Duration(days: 1)));
        }).toList();
        break;
      case 'month':
        final now = DateTime.now();
        filtered = filtered.where((sale) {
          return sale.createdAt.year == now.year &&
                 sale.createdAt.month == now.month;
        }).toList();
        break;
    }

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((sale) {
        return sale.customerName.toLowerCase().contains(query) ||
               sale.cashierName.toLowerCase().contains(query) ||
               sale.items.any((item) => item.productName.toLowerCase().contains(query));
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<SalesService>(
        builder: (context, salesService, child) {
          if (salesService.isLoading) {
            return const LoadingWidget(message: 'Loading sales history...');
          }

          final filteredSales = _getFilteredSales(salesService.sales);

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search sales...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(
                        color: Color(0xFF667eea),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),

              // Filter Display
              if (_selectedFilter != 'all')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Filtered by: ${_filters.firstWhere((f) => f['id'] == _selectedFilter)['name']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedFilter = 'all';
                          });
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),

              // Sales Summary
              _buildSalesSummary(filteredSales),

              const SizedBox(height: 16),

              // Sales List
              Expanded(
                child: filteredSales.isEmpty
                    ? const EmptyStateWidget(
                        message: 'No sales found',
                        icon: Icons.receipt_long,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredSales.length,
                        itemBuilder: (context, index) {
                          final sale = filteredSales[index];
                          return _buildSaleItem(sale);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const CommonBottomNavigation(currentIndex: 2),
    );
  }

  Widget _buildSalesSummary(List<SaleModel> sales) {
    final totalSales = sales.length;
    final totalRevenue = sales.fold<double>(0, (sum, sale) => sum + sale.total);
    final averageSale = totalSales > 0 ? totalRevenue / totalSales : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  totalSales.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Total Sales',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '\$${totalRevenue.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Revenue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '\$${averageSale.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Average',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleItem(SaleModel sale) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${sale.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    sale.customerName.isNotEmpty ? sale.customerName : 'Walk-in Customer',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDate(sale.createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  sale.paymentMethod.toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        subtitle: Text(
          '${sale.items.length} items • ${sale.cashierName}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Sale Details
                ...sale.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.productName} x${item.quantity}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:'),
                    Text('\$${sale.subtotal.toStringAsFixed(2)}'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tax:'),
                    Text('\$${sale.tax.toStringAsFixed(2)}'),
                  ],
                ),
                if (sale.paymentMethod == 'cash') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Amount Received:'),
                      Text('\$${sale.amountReceived.toStringAsFixed(2)}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Change:'),
                      Text('\$${sale.change.toStringAsFixed(2)}'),
                    ],
                  ),
                ],
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${sale.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF667eea),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _printReceipt(sale),
                        icon: const Icon(Icons.print),
                        label: const Text('Print'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF667eea),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _shareReceipt(sale),
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF667eea),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Sales'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _filters.map((filter) => RadioListTile<String>(
            title: Text(filter['name']),
            value: filter['id'],
            groupValue: _selectedFilter,
            onChanged: (value) {
              setState(() {
                _selectedFilter = value!;
              });
              Navigator.pop(context);
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _printReceipt(SaleModel sale) {
    // TODO: Implement receipt printing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Printing receipt...')),
    );
  }

  void _shareReceipt(SaleModel sale) {
    // TODO: Implement receipt sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing receipt...')),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
} 
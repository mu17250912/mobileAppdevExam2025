import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';
import '../constants/app_constants.dart';
import 'analytics_dashboard_screen.dart';

class CommissionerDashboardScreen extends StatefulWidget {
  const CommissionerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<CommissionerDashboardScreen> createState() => _CommissionerDashboardScreenState();
}

class _CommissionerDashboardScreenState extends State<CommissionerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _sortBy = 'timestamp';
  bool _sortDescending = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commissioner Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Paid'),
            Tab(text: 'Connected'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showAnalytics(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Cards
          _buildStatisticsCards(),
          
          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsList(null), // All
                _buildRequestsList('pending'), // Pending
                _buildRequestsList('paid'), // Paid
                _buildRequestsList('connected'), // Connected
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBulkActions(),
        icon: const Icon(Icons.batch_prediction),
        label: const Text('Bulk Actions'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('purchase_requests')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final requests = snapshot.data!.docs;
        final totalRequests = requests.length;
        final pendingRequests = requests.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'pending' && data['paymentStatus'] != 'paid';
        }).length;
        final paidRequests = requests.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['paymentStatus'] == 'paid' && data['status'] != 'connected';
        }).length;
        final connectedRequests = requests.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'connected';
        }).length;
        final totalRevenue = paidRequests * 50 + connectedRequests * 50;

        return Container(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Requests',
                  totalRequests.toString(),
                  Icons.receipt_long,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: _buildStatCard(
                  'Pending',
                  pendingRequests.toString(),
                  Icons.pending,
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: _buildStatCard(
                  'Paid',
                  paidRequests.toString(),
                  Icons.payment,
                  AppColors.info,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: _buildStatCard(
                  'Revenue',
                  '\$$totalRevenue',
                  Icons.attach_money,
                  AppColors.success,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.sm),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTextStyles.heading4.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(String? statusFilter) {
    Query query = FirebaseFirestore.instance
        .collection('purchase_requests')
        .orderBy(_sortBy, descending: _sortDescending);

    // Apply status filter
    if (statusFilter == 'pending') {
      query = query.where('status', isEqualTo: 'pending');
    } else if (statusFilter == 'paid') {
      query = query.where('paymentStatus', isEqualTo: 'paid')
          .where('status', isEqualTo: 'pending');
    } else if (statusFilter == 'connected') {
      query = query.where('status', isEqualTo: 'connected');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data?.docs ?? [];
        
        // Apply search filter
        final filteredRequests = _searchQuery.isEmpty
            ? requests
            : requests.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final searchLower = _searchQuery.toLowerCase();
                return data['buyerName']?.toString().toLowerCase().contains(searchLower) == true ||
                       data['propertyTitle']?.toString().toLowerCase().contains(searchLower) == true ||
                       data['contact']?.toString().toLowerCase().contains(searchLower) == true;
              }).toList();

        if (filteredRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  statusFilter == null ? 'No purchase requests yet' : 'No ${statusFilter} requests',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.md),
          itemCount: filteredRequests.length,
          itemBuilder: (context, index) {
            final request = filteredRequests[index].data() as Map<String, dynamic>;
            final requestId = filteredRequests[index].id;
            final status = request['status'] ?? 'pending';
            final paymentStatus = request['paymentStatus'] ?? 'pending';
            final isConnected = status == 'connected';
            final isPaid = paymentStatus == 'paid';

            return Card(
              margin: const EdgeInsets.only(bottom: AppSizes.md),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            request['propertyTitle'] ?? 'Unknown Property',
                            style: AppTextStyles.heading4.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatusChip(status, paymentStatus),
                      ],
                    ),
                    const SizedBox(height: AppSizes.sm),
                    
                    // Buyer Info
                    _buildInfoRow('Buyer', request['buyerName'] ?? 'Unknown'),
                    _buildInfoRow('Contact', request['contact'] ?? 'N/A'),
                    _buildInfoRow('Address', request['address'] ?? 'N/A'),
                    _buildInfoRow('Offer', '\$${request['offer'] ?? '0'}'),
                    if (request['moveInDate'] != null)
                      _buildInfoRow('Move-in Date', _formatDate(request['moveInDate'])),
                    
                    const SizedBox(height: AppSizes.sm),
                    
                    // Message
                    if (request['message']?.isNotEmpty == true) ...[
                      Text(
                        'Message:',
                        style: AppTextStyles.body2.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request['message'],
                        style: AppTextStyles.body2,
                      ),
                      const SizedBox(height: AppSizes.sm),
                    ],

                    // Actions
                    Row(
                      children: [
                        if (!isConnected && isPaid)
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.connect_without_contact),
                              label: const Text('Connect Buyer'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _connectBuyer(context, requestId),
                            ),
                          ),
                        if (!isPaid)
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.payment),
                              label: const Text('Awaiting Payment'),
                              onPressed: null,
                            ),
                          ),
                        const SizedBox(width: AppSizes.sm),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) => _handleMenuAction(value, requestId, request),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'details',
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline),
                                  SizedBox(width: 8),
                                  Text('View Details'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Edit Request'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete Request', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(String status, String paymentStatus) {
    Color color;
    String label;
    
    if (status == 'connected') {
      color = AppColors.success;
      label = 'Connected';
    } else if (paymentStatus == 'paid') {
      color = AppColors.warning;
      label = 'Paid';
    } else {
      color = Colors.grey;
      label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTextStyles.body2.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body2,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      return '${date.toDate().day}/${date.toDate().month}/${date.toDate().year}';
    }
    return date.toString();
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Requests'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Search by buyer name, property, or contact',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Requests'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Date (Newest First)'),
              leading: Radio<String>(
                value: 'timestamp',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                    _sortDescending = true;
                  });
                },
              ),
            ),
            ListTile(
              title: const Text('Date (Oldest First)'),
              leading: Radio<String>(
                value: 'timestamp',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                    _sortDescending = false;
                  });
                },
              ),
            ),
            ListTile(
              title: const Text('Buyer Name'),
              leading: Radio<String>(
                value: 'buyerName',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                    _sortDescending = false;
                  });
                },
              ),
            ),
            ListTile(
              title: const Text('Property Title'),
              leading: Radio<String>(
                value: 'propertyTitle',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                    _sortDescending = false;
                  });
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showAnalytics() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AnalyticsDashboardScreen(),
      ),
    );
  }

  void _showBulkActions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bulk Actions',
              style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.lg),
            
            // Bulk Connect Buyers
            _buildBulkActionTile(
              icon: Icons.connect_without_contact,
              title: 'Connect Paid Buyers',
              subtitle: 'Connect all buyers who have paid',
              onTap: () => _bulkConnectPaidBuyers(),
            ),
            
            // Export Data
            _buildBulkActionTile(
              icon: Icons.download,
              title: 'Export Requests',
              subtitle: 'Export all requests to CSV',
              onTap: () => _exportRequests(),
            ),
            
            // Bulk Status Update
            _buildBulkActionTile(
              icon: Icons.update,
              title: 'Update Status',
              subtitle: 'Update status for multiple requests',
              onTap: () => _showBulkStatusUpdate(),
            ),
            
            // Send Notifications
            _buildBulkActionTile(
              icon: Icons.notifications,
              title: 'Send Notifications',
              subtitle: 'Send notifications to buyers',
              onTap: () => _showBulkNotification(),
            ),
            
            const SizedBox(height: AppSizes.lg),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBulkActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      onTap: onTap,
    );
  }
  
  Future<void> _bulkConnectPaidBuyers() async {
    Navigator.of(context).pop(); // Close bottom sheet
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Connect Buyers'),
        content: const Text(
          'This will connect all buyers who have paid but are not yet connected. '
          'Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Connect All'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Connecting buyers...'),
            ],
          ),
        ),
      );
      
      try {
        // Get all paid but not connected requests
        final query = await FirebaseFirestore.instance
            .collection('purchase_requests')
            .where('paymentStatus', isEqualTo: 'paid')
            .where('status', isEqualTo: 'pending')
            .get();
        
        int connectedCount = 0;
        for (final doc in query.docs) {
          await doc.reference.update({'status': 'connected'});
          
          final data = doc.data();
          await NotificationService.createConnectionNotification(
            requestId: doc.id,
            buyerName: data['buyerName'] ?? 'Unknown',
            propertyTitle: data['propertyTitle'] ?? 'Unknown Property',
          );
          
          connectedCount++;
        }
        
        Navigator.of(context).pop(); // Close loading dialog
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully connected $connectedCount buyers!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        Navigator.of(context).pop(); // Close loading dialog
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
  
  Future<void> _exportRequests() async {
    Navigator.of(context).pop(); // Close bottom sheet
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Exporting data...'),
          ],
        ),
      ),
    );
    
    try {
      // Get all requests
      final query = await FirebaseFirestore.instance
          .collection('purchase_requests')
          .orderBy('timestamp', descending: true)
          .get();
      
      // Create CSV data
      final csvData = StringBuffer();
      csvData.writeln('Property,Buyer,Contact,Address,Offer,Status,Payment Status,Date');
      
      for (final doc in query.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        final date = timestamp != null ? _formatDate(timestamp) : 'Unknown';
        
        csvData.writeln([
          data['propertyTitle'] ?? 'Unknown',
          data['buyerName'] ?? 'Unknown',
          data['contact'] ?? 'N/A',
          data['address'] ?? 'N/A',
          data['offer'] ?? '0',
          data['status'] ?? 'pending',
          data['paymentStatus'] ?? 'pending',
          date,
        ].map((field) => '"${field.replaceAll('"', '""')}"').join(','));
      }
      
      Navigator.of(context).pop(); // Close loading dialog
      
      // Show success dialog with data
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Successfully exported ${query.docs.length} requests.'),
                const SizedBox(height: 16),
                const Text('CSV Data:'),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(csvData.toString()),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  void _showBulkStatusUpdate() {
    Navigator.of(context).pop(); // Close bottom sheet
    // TODO: Implement bulk status update
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk status update coming soon...')),
    );
  }
  
  void _showBulkNotification() {
    Navigator.of(context).pop(); // Close bottom sheet
    // TODO: Implement bulk notification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk notification coming soon...')),
    );
  }

  void _handleMenuAction(String action, String requestId, Map<String, dynamic> request) {
    switch (action) {
      case 'details':
        _showRequestDetails(context, request);
        break;
      case 'edit':
        _showEditRequest(context, requestId, request);
        break;
      case 'delete':
        _showDeleteConfirmation(context, requestId);
        break;
    }
  }

  void _connectBuyer(BuildContext context, String requestId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect Buyer'),
        content: const Text(
          'Are you sure you want to connect this buyer with the property owner? '
          'This will mark the request as connected and notify both parties.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _updateRequestStatus(requestId, 'connected');
              
              // Get request data for notification
              final requestDoc = await FirebaseFirestore.instance
                  .collection('purchase_requests')
                  .doc(requestId)
                  .get();
              
              if (requestDoc.exists) {
                final requestData = requestDoc.data() as Map<String, dynamic>;
                
                // Create notification for connection
                await NotificationService.createConnectionNotification(
                  requestId: requestId,
                  buyerName: requestData['buyerName'] ?? 'Unknown',
                  propertyTitle: requestData['propertyTitle'] ?? 'Unknown Property',
                );
              }
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Buyer connected successfully!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateRequestStatus(String requestId, String status) async {
    await FirebaseFirestore.instance
        .collection('purchase_requests')
        .doc(requestId)
        .update({'status': status});
  }

  void _showRequestDetails(BuildContext context, Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Property', request['propertyTitle'] ?? 'Unknown'),
              _buildInfoRow('Buyer', request['buyerName'] ?? 'Unknown'),
              _buildInfoRow('Contact', request['contact'] ?? 'N/A'),
              _buildInfoRow('Address', request['address'] ?? 'N/A'),
              _buildInfoRow('Offer', '\$${request['offer'] ?? '0'}'),
              if (request['moveInDate'] != null)
                _buildInfoRow('Move-in Date', _formatDate(request['moveInDate'])),
              _buildInfoRow('Status', request['status'] ?? 'pending'),
              _buildInfoRow('Payment', request['paymentStatus'] ?? 'pending'),
              if (request['message']?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  'Message:',
                  style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(request['message']),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditRequest(BuildContext context, String requestId, Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _EditRequestForm(
        requestId: requestId,
        request: request,
        onSave: () {
          Navigator.of(context).pop();
          setState(() {}); // Refresh the list
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String requestId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Request'),
        content: const Text(
          'Are you sure you want to delete this purchase request? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await FirebaseFirestore.instance
                  .collection('purchase_requests')
                  .doc(requestId)
                  .delete();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Request deleted successfully!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _EditRequestForm extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> request;
  final VoidCallback onSave;

  const _EditRequestForm({
    required this.requestId,
    required this.request,
    required this.onSave,
  });

  @override
  State<_EditRequestForm> createState() => _EditRequestFormState();
}

class _EditRequestFormState extends State<_EditRequestForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _buyerNameController;
  late TextEditingController _contactController;
  late TextEditingController _addressController;
  late TextEditingController _offerController;
  late TextEditingController _messageController;
  String _status = 'pending';
  String _paymentStatus = 'pending';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _buyerNameController = TextEditingController(text: widget.request['buyerName'] ?? '');
    _contactController = TextEditingController(text: widget.request['contact'] ?? '');
    _addressController = TextEditingController(text: widget.request['address'] ?? '');
    _offerController = TextEditingController(text: widget.request['offer']?.toString() ?? '');
    _messageController = TextEditingController(text: widget.request['message'] ?? '');
    _status = widget.request['status'] ?? 'pending';
    _paymentStatus = widget.request['paymentStatus'] ?? 'pending';
  }

  @override
  void dispose() {
    _buyerNameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _offerController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSizes.lg,
        right: AppSizes.lg,
        top: AppSizes.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Edit Request',
                  style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            
            // Property Title (read-only)
            TextFormField(
              initialValue: widget.request['propertyTitle'] ?? 'Unknown Property',
              decoration: const InputDecoration(
                labelText: 'Property',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            const SizedBox(height: AppSizes.md),
            
            // Buyer Name
            TextFormField(
              controller: _buyerNameController,
              decoration: const InputDecoration(
                labelText: 'Buyer Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter buyer name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.md),
            
            // Contact
            TextFormField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: 'Contact',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter contact information';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.md),
            
            // Address
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter address';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.md),
            
            // Offer
            TextFormField(
              controller: _offerController,
              decoration: const InputDecoration(
                labelText: 'Offer Amount',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter offer amount';
                }
                final num? offer = num.tryParse(value);
                if (offer == null || offer <= 0) {
                  return 'Enter a valid offer amount';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.md),
            
            // Status
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'connected', child: Text('Connected')),
                DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
              ],
              onChanged: (value) {
                setState(() {
                  _status = value!;
                });
              },
            ),
            const SizedBox(height: AppSizes.md),
            
            // Payment Status
            DropdownButtonFormField<String>(
              value: _paymentStatus,
              decoration: const InputDecoration(
                labelText: 'Payment Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'paid', child: Text('Paid')),
                DropdownMenuItem(value: 'failed', child: Text('Failed')),
              ],
              onChanged: (value) {
                setState(() {
                  _paymentStatus = value!;
                });
              },
            ),
            const SizedBox(height: AppSizes.md),
            
            // Message
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppSizes.lg),
            
            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveRequest,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Changes'),
            ),
            const SizedBox(height: AppSizes.md),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRequest() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      await FirebaseFirestore.instance
          .collection('purchase_requests')
          .doc(widget.requestId)
          .update({
        'buyerName': _buyerNameController.text.trim(),
        'contact': _contactController.text.trim(),
        'address': _addressController.text.trim(),
        'offer': double.tryParse(_offerController.text) ?? 0,
        'message': _messageController.text.trim(),
        'status': _status,
        'paymentStatus': _paymentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onSave();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating request: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
} 
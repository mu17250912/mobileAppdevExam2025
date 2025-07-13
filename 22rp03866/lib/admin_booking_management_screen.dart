import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme/colors.dart';

class AdminBookingManagementScreen extends StatefulWidget {
  const AdminBookingManagementScreen({super.key});

  @override
  State<AdminBookingManagementScreen> createState() => _AdminBookingManagementScreenState();
}

class _AdminBookingManagementScreenState extends State<AdminBookingManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _selectedStatus = 'All';

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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Booking Management',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.onPrimary,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withOpacity(0.7),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Confirmed'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingList(null), // All bookings
          _buildBookingList('Confirmed'),
          _buildBookingList('Completed'),
          _buildBookingList('Cancelled'),
        ],
      ),
    );
  }

  Widget _buildBookingList(String? statusFilter) {
    Query query = FirebaseFirestore.instance
        .collection('bookings')
        .orderBy('timestamp', descending: true);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_note, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No bookings found!',
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
                Text(
                  'Bookings will appear here once users make reservations.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final bookingData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final bookingId = snapshot.data!.docs[index].id;
            final status = bookingData['status'] ?? 'Unknown';
            
            Color statusColor = Colors.grey;
            if (status == 'Confirmed') {
              statusColor = AppColors.success;
            } else if (status == 'Completed') {
              statusColor = AppColors.info;
            } else if (status == 'Cancelled') {
              statusColor = AppColors.danger;
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bookingData['tripName'] ?? 'Unknown Trip',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Booked by: ${bookingData['userName'] ?? 'Unknown User'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoRow('Date', _formatTimestamp(bookingData['bookingDate'])),
                        ),
                        Expanded(
                          child: _buildInfoRow('People', '${bookingData['numberOfPeople'] ?? 1}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoRow('Price', '\$${bookingData['totalPrice'] ?? '0'}'),
                        ),
                        Expanded(
                          child: _buildInfoRow('Premium', bookingData['isPremiumBooking'] == true ? 'Yes' : 'No'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (status == 'Pending')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({'status': 'Confirmed'});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Booking approved!')),
                              );
                            },
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({'status': 'Cancelled'});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Booking denied!')),
                              );
                            },
                            icon: const Icon(Icons.close, color: Colors.white),
                            label: const Text('Deny'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (status == 'Confirmed') ...[
                          ElevatedButton.icon(
                            onPressed: () => _updateBookingStatus(context, bookingId, 'Completed'),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Mark Complete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _updateBookingStatus(context, bookingId, 'Cancelled'),
                            icon: const Icon(Icons.cancel, size: 16),
                            label: const Text('Cancel'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                        if (status == 'Completed' || status == 'Cancelled') ...[
                          ElevatedButton.icon(
                            onPressed: () => _updateBookingStatus(context, bookingId, 'Confirmed'),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Reconfirm'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                        ElevatedButton.icon(
                          onPressed: () => _showDeleteConfirmation(context, bookingId, bookingData['tripName']),
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.textSecondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
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

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _updateBookingStatus(BuildContext context, String bookingId, String newStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Booking Status'),
        content: Text('Are you sure you want to change the status to "$newStatus"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
                  'status': newStatus,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Booking status updated to $newStatus')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update booking: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'Completed' ? AppColors.success : 
                             newStatus == 'Cancelled' ? AppColors.danger : 
                             AppColors.primary,
            ),
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String bookingId, String tripName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Booking'),
        content: Text('Are you sure you want to delete the booking for "$tripName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('bookings').doc(bookingId).delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking deleted successfully')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete booking: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final dateTime = timestamp.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (timestamp is String) {
      try {
        final dateTime = DateTime.parse(timestamp);
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      } catch (e) {
        return 'Invalid date';
      }
    }
    return 'N/A';
  }
} 
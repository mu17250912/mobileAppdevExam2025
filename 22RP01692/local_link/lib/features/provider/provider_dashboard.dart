import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:badges/badges.dart' as badges;
import 'package:fl_chart/fl_chart.dart';
import '../../services/notification_service.dart';
import 'provider_settings_screen.dart';
import 'provider_users_screen.dart';
import 'provider_notifications_screen.dart';
import 'provider_subscription_screen.dart';

class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({super.key});
  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const _DashboardHomeTab(),
    const ProviderUsersScreen(),
    const ProviderNotificationsScreen(),
    const ProviderSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in as a provider.')),
      );
    }
    
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white.withOpacity(0.7),
            backgroundColor: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).colors.first,
            elevation: 0,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 11,
            ),
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _currentIndex == 0 
                        ? Colors.white.withOpacity(0.2) 
                        : Colors.transparent,
                  ),
                  child: const Icon(Icons.dashboard_rounded, size: 24),
                ),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _currentIndex == 1 
                        ? Colors.white.withOpacity(0.2) 
                        : Colors.transparent,
                  ),
                  child: const Icon(Icons.people_rounded, size: 24),
                ),
                label: 'Users',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _currentIndex == 2 
                        ? Colors.white.withOpacity(0.2) 
                        : Colors.transparent,
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user!.uid)
                        .collection('notifications')
                        .where('read', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      int unread = snapshot.data?.docs.length ?? 0;
                      return badges.Badge(
                        showBadge: unread > 0,
                        badgeStyle: badges.BadgeStyle(
                          badgeColor: Colors.red,
                          padding: const EdgeInsets.all(4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        badgeContent: Text(
                          unread > 99 ? '99+' : '$unread', 
                          style: const TextStyle(
                            color: Colors.white, 
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Icon(Icons.notifications_rounded, size: 24),
                      );
                    },
                  ),
                ),
                label: 'Notifications',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _currentIndex == 3 
                        ? Colors.white.withOpacity(0.2) 
                        : Colors.transparent,
                  ),
                  child: const Icon(Icons.settings_rounded, size: 24),
                ),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHomeTab extends StatefulWidget {
  const _DashboardHomeTab();

  @override
  State<_DashboardHomeTab> createState() => _DashboardHomeTabState();
}

class _DashboardHomeTabState extends State<_DashboardHomeTab> {
  String _selectedStatus = 'all';
  DateTimeRange? _selectedDateRange;
  String _selectedCategory = 'all';

  void _openChat(String providerId, String userId, String userName) async {
    // Create or get chat document
    final chatId = providerId.compareTo(userId) < 0 ? providerId + '_' + userId : userId + '_' + providerId;
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    final chatDoc = await chatRef.get();
    if (!chatDoc.exists) {
      await chatRef.set({
        'chatId': chatId,
        'providerId': providerId,
        'userId': userId,
        'lastMessage': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(chatId: chatId, providerId: providerId, userId: userId, userName: userName),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in as a provider.')),
      );
    }
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // Custom App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Provider Dashboard',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Manage your services & bookings',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.notifications_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Service Categories Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.category_rounded,
                                color: Color(0xFF3B82F6),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Service Categories',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: () => _showAddCategoryDialog(context),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add Category'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Service Categories List
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('serviceCategories')
                              .where('providerId', isEqualTo: user!.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            
                            final categories = snapshot.data?.docs ?? [];
                            
                            if (categories.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.category_outlined,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No service categories yet',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add your first service category to get started',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            return Column(
                              children: [
                                ...categories.map((doc) {
                                  final data = doc.data() as Map<String, dynamic>? ?? {};
                                  final categoryName = data['name'] ?? '';
                                  final categoryDescription = data['description'] ?? '';
                                  final categoryId = doc.id;
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      leading: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.category_rounded,
                                          color: Color(0xFF3B82F6),
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        categoryName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Text(
                                        categoryDescription,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      trailing: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _showEditCategoryDialog(context, categoryId, categoryName, categoryDescription);
                                            } else if (value == 'delete') {
                                              _showDeleteCategoryDialog(context, categoryId, categoryName);
              }
            },
            itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                child: Row(
                  children: [
                                                  Icon(Icons.edit_rounded, color: Color(0xFF3B82F6)),
                    SizedBox(width: 8),
                                                  Text('Edit'),
                  ],
                ),
              ),
                                            const PopupMenuItem(
                                              value: 'delete',
                child: Row(
                  children: [
                                                  Icon(Icons.delete_rounded, color: Colors.red),
                    SizedBox(width: 8),
                                                  Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Filters Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
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
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.filter_list_rounded,
                                color: Color(0xFF10B981),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Filters',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: DropdownButton<String>(
                                value: _selectedStatus,
                                underline: const SizedBox(),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                items: const [
                                  DropdownMenuItem(value: 'all', child: Text('All Status')),
                                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                                  DropdownMenuItem(value: 'complete', child: Text('Complete')),
                                  DropdownMenuItem(value: 'incomplete', child: Text('Incomplete')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedStatus = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.date_range_rounded, size: 16),
                                label: Text(
                                  _selectedDateRange == null
                                      ? 'All Dates'
                                      : '${_selectedDateRange!.start.year}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.day} - ${_selectedDateRange!.end.year}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.day}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  side: BorderSide(color: Colors.grey[300]!),
                                ),
                                onPressed: () async {
                                  final now = DateTime.now();
                                  final picked = await showDateRangePicker(
                                    context: context,
                                    firstDate: DateTime(now.year - 2),
                                    lastDate: DateTime(now.year + 2),
                                    initialDateRange: _selectedDateRange,
                                  );
                                  if (picked != null) setState(() => _selectedDateRange = picked);
                                },
                              ),
                            ),
                            if (_selectedDateRange != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                onPressed: () => setState(() => _selectedDateRange = null),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.grey[100],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bookings Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('providerId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      );
          }
          if (snapshot.hasError) {
            final errorMsg = snapshot.error.toString();
            if (errorMsg.contains('index')) {
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.error_outline_rounded,
                                    color: Colors.red,
                                    size: 48,
                                  ),
                                ),
                                const SizedBox(height: 16),
                      const Text(
                        'A Firestore index is required for this query.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.red,
                                  ),
                        textAlign: TextAlign.center,
                      ),
                                const SizedBox(height: 8),
                      Text(
                        errorMsg,
                                  style: const TextStyle(color: Colors.black87, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Please click the link above to create the index, then reload the app.',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text('Error: $errorMsg'),
                          ),
                        ),
                      );
                    }
                    var bookings = snapshot.data?.docs ?? [];
                    // Sort bookings by date (newest first)
                    bookings.sort((a, b) {
                      final aDate = (a['date'] as Timestamp?)?.toDate() ?? DateTime(1970);
                      final bDate = (b['date'] as Timestamp?)?.toDate() ?? DateTime(1970);
                      return bDate.compareTo(aDate);
                    });
                    // Filter by status
                    if (_selectedStatus != 'all') {
                      bookings = bookings.where((doc) => (doc['status'] ?? '') == _selectedStatus).toList();
                    }
                    // Filter by date range
                    if (_selectedDateRange != null) {
                      bookings = bookings.where((doc) {
                        final date = (doc['date'] as Timestamp?)?.toDate();
                        if (date == null) return false;
                        return date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                            date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
                      }).toList();
                    }
          int total = bookings.length;
          int completed = bookings.where((doc) => (doc['status'] ?? '') == 'complete').length;
          int pending = bookings.where((doc) => (doc['status'] ?? '') == 'pending').length;
                    
          return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                        // Summary Cards
                        if (total > 0) ...[
                          Row(
                      children: [
                              Expanded(
                                child: _SummaryCard(
                                  title: 'Total Bookings',
                                  value: total.toString(),
                                  icon: Icons.book_rounded,
                                  color: const Color(0xFF3B82F6),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _SummaryCard(
                                  title: 'Completed',
                                  value: completed.toString(),
                                  icon: Icons.check_circle_rounded,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _SummaryCard(
                                  title: 'Pending',
                                  value: pending.toString(),
                                  icon: Icons.pending_rounded,
                                  color: const Color(0xFFF59E0B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                        
                        // Bookings List
              if (bookings.isEmpty)
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.assignment_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No bookings assigned to you yet.',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Bookings will appear here once users request your services',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                )
              else
                          Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.assignment_rounded,
                                      color: Color(0xFF8B5CF6),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Recent Bookings',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...bookings.map((doc) {
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      final Timestamp? dateTs = data['date'] as Timestamp?;
                      final DateTime? date = dateTs?.toDate();
                                final status = data['status'] ?? 'pending';
                                final statusIcon = status == 'pending'
                                    ? Icons.hourglass_empty_rounded
                                    : status == 'complete'
                                        ? Icons.check_circle_rounded
                                        : Icons.info_rounded;
                                final statusColor = status == 'pending' 
                                    ? const Color(0xFFF59E0B)
                                    : status == 'complete'
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF6B7280);
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                        child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        statusIcon,
                                        color: statusColor,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      (data['serviceType']?.toString().toUpperCase() ?? 'Service'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (date != null)
                                          Text(
                                            'Date: ${DateFormat('yyyy-MM-dd – kk:mm').format(date)}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        Text(
                                          'User: ${data['contactname'] ?? ''} (${data['contactphone'] ?? ''})',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: statusColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                status.toUpperCase(),
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: (data['paymentstatus'] == 'paid' 
                                                    ? const Color(0xFF10B981) 
                                                    : const Color(0xFFF59E0B)).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                (data['paymentstatus'] ?? 'unpaid').toUpperCase(),
                                                style: TextStyle(
                                                  color: data['paymentstatus'] == 'paid' 
                                                      ? const Color(0xFF10B981) 
                                                      : const Color(0xFFF59E0B),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Price: ${data['price'] ?? ''} FRW',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.message_rounded,
                                            color: Color(0xFF3B82F6),
                                          ),
                                          tooltip: 'Message User',
                                          onPressed: () => _openChat(
                                            user.uid,
                                            data['userId'] ?? '',
                                            data['contactname'] ?? '',
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_rounded,
                                            color: Color(0xFF6B7280),
                                          ),
                                          tooltip: 'Edit Booking',
                                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => _BookingDetailsDialog(
                                bookingId: doc.id,
                                data: data,
                              ),
                            );
                          },
                                        ),
                                      ],
                                    ),
                        ),
                                );
                              }).toList(),
                            ],
                          ),
                      ],
                      );
                    },
                ),
                  ),
                ),
            ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check subscription limits
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    
    final userData = userDoc.data() as Map<String, dynamic>? ?? {};
    final currentPlan = userData['subscriptionPlan'] ?? 'free';
    
    // Get current category count
    final categoriesSnapshot = await FirebaseFirestore.instance
        .collection('serviceCategories')
        .where('providerId', isEqualTo: user.uid)
        .get();
    
    final currentCount = categoriesSnapshot.docs.length;
    final maxAllowed = _getMaxCategories(currentPlan);
    
    if (currentCount >= maxAllowed) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Limit Reached'),
          content: Text(
            'You have reached the maximum number of service categories for your $currentPlan plan. '
            'Upgrade to add more categories.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProviderSubscriptionScreen(),
                  ),
                );
              },
              child: const Text('Upgrade'),
            ),
          ],
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Service Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Categories: $currentCount / $maxAllowed'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g., Plumbing, Electrical, Cleaning',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Brief description of the category',
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
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('serviceCategories')
                    .add({
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'providerId': user.uid,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, String categoryId, String currentName, String currentDescription) {
    final nameController = TextEditingController(text: currentName);
    final descriptionController = TextEditingController(text: currentDescription);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Service Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g., Plumbing, Electrical, Cleaning',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Brief description of the category',
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
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('serviceCategories')
                    .doc(categoryId)
                    .update({
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(BuildContext context, String categoryId, String categoryName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "$categoryName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('serviceCategories')
                  .doc(categoryId)
                  .delete();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  int _getMaxCategories(String plan) {
    switch (plan) {
      case 'basic':
        return 15;
      case 'premium':
      case 'enterprise':
        return 999; // Unlimited for practical purposes
      default:
        return 5; // Free plan
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingDetailsDialog extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> data;
  const _BookingDetailsDialog({required this.bookingId, required this.data});
  @override
  Widget build(BuildContext context) {
    final Timestamp? dateTs = data['date'] as Timestamp?;
    final DateTime? date = dateTs?.toDate();
    return AlertDialog(
      title: const Text('Booking Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service: ${data['serviceType'] ?? ''}'),
            if (date != null) Text('Date: ${DateFormat('yyyy-MM-dd – kk:mm').format(date)}'),
            Text('User: ${data['contactname'] ?? ''}'),
            Text('Phone: ${data['contactphone'] ?? ''}'),
            Text('Location: ${data['location'] ?? ''}'),
            Text('Notes: ${data['notes'] ?? ''}'),
            Text('Status: ${data['status'] ?? 'pending'}'),
            Text('Payment: ${data['paymentstatus'] ?? 'unpaid'}'),
            Text('Price: ${data['price'] ?? ''} frw'),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.phone, color: Colors.green),
                  onPressed: () {
                    // Implement call action (e.g., using url_launcher)
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.message, color: Colors.blue),
                  onPressed: () {
                    // Implement message action
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _EditBookingDialog(
              bookingId: bookingId,
              currentStatus: data['status'] ?? 'pending',
              currentPayment: data['paymentstatus'] ?? 'unpaid',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _EditBookingDialog extends StatefulWidget {
  final String bookingId;
  final String currentStatus;
  final String currentPayment;
  const _EditBookingDialog({required this.bookingId, required this.currentStatus, required this.currentPayment});

  @override
  State<_EditBookingDialog> createState() => _EditBookingDialogState();
}

class _EditBookingDialogState extends State<_EditBookingDialog> {
  late String _status;
  late String _payment;
  bool _loading = false;

  bool get _statusFinalized => _status == 'complete' || _status == 'incomplete';

  @override
  void initState() {
    super.initState();
    _status = widget.currentStatus;
    _payment = widget.currentPayment;
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update({
      'status': _status,
      'paymentstatus': _payment,
    });
    setState(() => _loading = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Booking'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _status,
            items: const [
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'complete', child: Text('Complete')),
              DropdownMenuItem(value: 'incomplete', child: Text('Incomplete')),
            ],
            onChanged: _statusFinalized ? null : (val) => setState(() => _status = val!),
            decoration: const InputDecoration(labelText: 'Status'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _payment,
            items: const [
              DropdownMenuItem(value: 'unpaid', child: Text('Unpaid')),
              DropdownMenuItem(value: 'paid', child: Text('Paid')),
            ],
            onChanged: _statusFinalized ? null : (val) => setState(() => _payment = val!),
            decoration: const InputDecoration(labelText: 'Payment Status'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading || _statusFinalized ? null : _save,
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String providerId;
  final String userId;
  final String userName;
  const ChatScreen({required this.chatId, required this.providerId, required this.userId, required this.userName, super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final senderId = widget.providerId; // Provider is sender in this screen
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
          'senderId': senderId,
          'text': text,
          'timestamp': FieldValue.serverTimestamp(),
        });
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .update({
          'lastMessage': text,
          'updatedAt': FieldValue.serverTimestamp(),
        });
    
    // Send notification to user about the message
    await NotificationService.sendMessageNotification(
      providerId: widget.userId, // Send to user
      userId: widget.providerId, // Provider is sender
      userName: 'Provider', // You can get actual provider name from Firestore
      message: text,
    );
    
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat with ${widget.userName}')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data?.docs ?? [];
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>? ?? {};
                    final isProvider = data['senderId'] == widget.providerId;
                    return Align(
                      alignment: isProvider ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isProvider ? Colors.green[100] : Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(data['text'] ?? '', style: const TextStyle(fontSize: 16)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'user_store.dart';
import 'user.dart';
import 'car_store.dart';
import 'booking_store.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text(
          'Analytics Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Cards
            _buildOverviewSection(),
            const SizedBox(height: 24),
            
            // User Statistics
            _buildUserStatisticsSection(),
            const SizedBox(height: 24),
            
            // Booking Statistics
            _buildBookingStatisticsSection(),
            const SizedBox(height: 24),
            
            // Revenue Statistics
            _buildRevenueStatisticsSection(),
            const SizedBox(height: 24),
            
            // Recent Activity
            _buildRecentActivitySection(),
            const SizedBox(height: 24),
            
            // System Health
            _buildSystemHealthSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'System Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StreamBuilder<int>(
                stream: UserStore.getTotalUsersCountStream(),
                builder: (context, snapshot) {
                  return StreamBuilder<int>(
                    stream: UserStore.getActiveUsersCountStream(),
                    builder: (context, activeSnapshot) {
                      return _buildOverviewCard(
                        'Total Users',
                        (snapshot.data ?? 0).toString(),
                        Icons.people,
                        Colors.blue,
                        '${activeSnapshot.data ?? 0} active',
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StreamBuilder<List<Car>>(
                stream: CarStore.getCarsStream(),
                builder: (context, snapshot) {
                  return _buildOverviewCard(
                    'Total Cars',
                    (snapshot.data?.length ?? 0).toString(),
                    Icons.directions_car,
                    Colors.orange,
                    'Available for rent',
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StreamBuilder<List<Booking>>(
                stream: BookingStore.getBookingsStream(),
                builder: (context, snapshot) {
                  return _buildOverviewCard(
                    'Total Bookings',
                    (snapshot.data?.length ?? 0).toString(),
                    Icons.book_online,
                    Colors.green,
                    'All time bookings',
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StreamBuilder<Map<String, int>>(
                stream: BookingStore.getRevenueStatisticsStream(),
                builder: (context, snapshot) {
                  return _buildOverviewCard(
                    'Total Revenue',
                    '${snapshot.data?['total'] ?? 0} RWF',
                    Icons.attach_money,
                    Colors.purple,
                    'Completed bookings',
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4A5568),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF718096),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User Statistics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<int>(
          stream: UserStore.getTotalUsersCountStream(),
          builder: (context, totalSnapshot) {
            return StreamBuilder<int>(
              stream: UserStore.getActiveUsersCountStream(),
              builder: (context, activeSnapshot) {
                return StreamBuilder<int>(
                  stream: UserStore.getAdminCountStream(),
                  builder: (context, adminSnapshot) {
                    final totalUsers = totalSnapshot.data ?? 0;
                    final activeUsers = activeSnapshot.data ?? 0;
                    final inactiveUsers = totalUsers - activeUsers;
                    final adminUsers = adminSnapshot.data ?? 0;
                    final standardUsers = totalUsers - adminUsers;
                    
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildStatRow('Active Users', activeUsers, totalUsers, Colors.green),
                            const SizedBox(height: 12),
                            _buildStatRow('Inactive Users', inactiveUsers, totalUsers, Colors.red),
                            const SizedBox(height: 12),
                            _buildStatRow('Administrators', adminUsers, totalUsers, Colors.purple),
                            const SizedBox(height: 12),
                            _buildStatRow('Standard Users', standardUsers, totalUsers, Colors.blue),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildBookingStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Booking Statistics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<Booking>>(
          stream: BookingStore.getBookingsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            
            final allBookings = snapshot.data ?? [];
            final pendingBookings = allBookings.where((b) => b.status == 'pending').toList();
            final confirmedBookings = allBookings.where((b) => b.status == 'confirmed').toList();
            final completedBookings = allBookings.where((b) => b.status == 'completed').toList();
            final cancelledBookings = allBookings.where((b) => b.status == 'cancelled').toList();
            
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildStatRow('Pending', pendingBookings.length, allBookings.length, Colors.orange),
                    const SizedBox(height: 12),
                    _buildStatRow('Confirmed', confirmedBookings.length, allBookings.length, Colors.blue),
                    const SizedBox(height: 12),
                    _buildStatRow('Completed', completedBookings.length, allBookings.length, Colors.green),
                    const SizedBox(height: 12),
                    _buildStatRow('Cancelled', cancelledBookings.length, allBookings.length, Colors.red),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRevenueStatisticsSection() {
    return StreamBuilder<Map<String, int>>(
      stream: BookingStore.getRevenueStatisticsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Revenue Statistics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
          );
        }
        
        final totalRevenue = snapshot.data?['total'] ?? 0;
        final completedCount = snapshot.data?['completed'] ?? 0;
        final averageRevenue = completedCount > 0 ? totalRevenue / completedCount : 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildStatRow('Total Revenue', totalRevenue, totalRevenue, Colors.green, isRevenue: true),
                    const SizedBox(height: 12),
                    _buildStatRow('Completed Bookings', completedCount, completedCount, Colors.blue),
                    const SizedBox(height: 12),
                    _buildStatRow('Average Revenue', averageRevenue.round(), averageRevenue.round(), Colors.purple, isRevenue: true),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatRow(String label, int value, int total, Color color, {bool isRevenue = false}) {
    final percentage = total > 0 ? (value / total * 100).round() : 0;
    final displayValue = isRevenue ? '${value} RWF' : value.toString();
    
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4A5568),
            ),
          ),
        ),
        Text(
          isRevenue ? displayValue : '$displayValue ($percentage%)',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity (Last 7 Days)',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<User>>(
          stream: UserStore.getRecentlyActiveUsersStream(days: 7),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            
            final recentUsers = snapshot.data ?? [];
            
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: recentUsers.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No recent activity',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF718096),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentUsers.length > 5 ? 5 : recentUsers.length,
                      itemBuilder: (context, index) {
                        final user = recentUsers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: user.isAdmin ? Colors.purple : Colors.blue,
                            child: Text(
                              user.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            user.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Last login: ${user.formattedLastLogin}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: user.isAdmin ? Colors.purple.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.roleDisplayName,
                              style: TextStyle(
                                fontSize: 12,
                                color: user.isAdmin ? Colors.purple : Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSystemHealthSection() {
    return StreamBuilder<int>(
      stream: UserStore.getTotalUsersCountStream(),
      builder: (context, totalSnapshot) {
        return StreamBuilder<int>(
          stream: UserStore.getActiveUsersCountStream(),
          builder: (context, activeSnapshot) {
            final totalUsers = totalSnapshot.data ?? 0;
            final activeUsers = activeSnapshot.data ?? 0;
            final systemHealth = totalUsers > 0 ? (activeUsers / totalUsers * 100).round() : 100;
            
            Color healthColor;
            String healthStatus;
            
            if (systemHealth >= 80) {
              healthColor = Colors.green;
              healthStatus = 'Excellent';
            } else if (systemHealth >= 60) {
              healthColor = Colors.orange;
              healthStatus = 'Good';
            } else {
              healthColor = Colors.red;
              healthStatus = 'Needs Attention';
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'System Health',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.health_and_safety,
                              color: healthColor,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    healthStatus,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: healthColor,
                                    ),
                                  ),
                                  Text(
                                    'System Status',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF718096),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '$systemHealth%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: healthColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: systemHealth / 100,
                          backgroundColor: Colors.grey.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                          minHeight: 8,
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<List<Car>>(
                          stream: CarStore.getCarsStream(),
                          builder: (context, carsSnapshot) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildHealthMetric('Active Users', activeUsers.toString(), Icons.check_circle, Colors.green),
                                _buildHealthMetric('Inactive Users', (totalUsers - activeUsers).toString(), Icons.cancel, Colors.red),
                                _buildHealthMetric('Total Cars', (carsSnapshot.data?.length ?? 0).toString(), Icons.directions_car, Colors.orange),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHealthMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF718096),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
} 
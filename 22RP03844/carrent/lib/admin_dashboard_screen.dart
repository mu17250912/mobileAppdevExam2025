import 'package:flutter/material.dart';
import 'user_store.dart';
import 'user.dart';
import 'car_store.dart';
import 'booking_store.dart';
import 'login_screen.dart';
import 'user_management_screen.dart';
import 'admin_analytics_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String formatAnyDate(dynamic value) {
  if (value == null) return '';
  if (value is String) {
    try {
      final date = DateTime.parse(value);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return value;
    }
  }
  if (value is DateTime) {
    return '${value.day}/${value.month}/${value.year}';
  }
  if (value is Timestamp) {
    final date = value.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
  return value.toString();
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  String _searchQuery = '';

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onUserStatusChanged(User user, bool isActive) async {
    try {
      if (isActive) {
        await UserStore.activateUser(user.id);
      } else {
        await UserStore.deactivateUser(user.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${isActive ? 'activated' : 'deactivated'} successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onUserDeleted(String userId) async {
    try {
      await UserStore.deleteUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCarManagementTab() {
    return StreamBuilder<List<Car>>(
      stream: CarStore.getCarsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final cars = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Manage Cars', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _showAddCarDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Car'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...cars.map((car) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: car.image.isNotEmpty
                      ? Image.network(
                          car.image,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.directions_car, size: 40),
                        )
                      : const Icon(Icons.directions_car, size: 40),
                  title: Text('${car.brand} ${car.model}'),
                  subtitle: Text('Price: ${car.price} RWF/day'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditCarDialog(car),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteCar(car.id),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  void _showAddCarDialog() {
    String brand = '', model = '', price = '', image = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Car'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Brand'), onChanged: (v) => brand = v),
            TextField(decoration: const InputDecoration(labelText: 'Model'), onChanged: (v) => model = v),
            TextField(decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number, onChanged: (v) => price = v),
            TextField(decoration: const InputDecoration(labelText: 'Image URL'), onChanged: (v) => image = v),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (brand.isNotEmpty && model.isNotEmpty && price.isNotEmpty) {
                try {
                  final car = Car(
                    id: 'car_${DateTime.now().millisecondsSinceEpoch}_${brand}_$model',
                    brand: brand,
                    model: model,
                    price: int.tryParse(price) ?? 0,
                    image: image,
                    createdAt: DateTime.now(),
                  );
                  await CarStore.createCar(car);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Car added successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add car: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditCarDialog(Car car) {
    String brand = car.brand, model = car.model, price = car.price.toString(), image = car.image;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Car'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Brand'),
              controller: TextEditingController(text: brand),
              onChanged: (v) => brand = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Model'),
              controller: TextEditingController(text: model),
              onChanged: (v) => model = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: price),
              onChanged: (v) => price = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Image URL'),
              controller: TextEditingController(text: image),
              onChanged: (v) => image = v,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (brand.isNotEmpty && model.isNotEmpty && price.isNotEmpty) {
                try {
                  final updatedCar = car.copyWith(
                    brand: brand,
                    model: model,
                    price: int.tryParse(price) ?? car.price,
                    image: image,
                    updatedAt: DateTime.now(),
                  );
                  await CarStore.updateCar(updatedCar);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Car updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update car: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteCar(String carId) async {
    try {
      await CarStore.deleteCar(carId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Car deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete car: ${e.toString()}')),
      );
    }
  }

  Widget _buildBookingsTab() {
    return StreamBuilder<List<Booking>>(
      stream: BookingStore.getBookingsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final bookings = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Manage Bookings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...bookings.map((booking) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text('${booking.carBrand} ${booking.carModel}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<User?>(
                        future: UserStore.getUserById(booking.userId),
                        builder: (context, snapshot) {
                          return Text('User: ${snapshot.data?.name ?? 'Unknown'}');
                        },
                      ),
                      Text('Dates: ${formatAnyDate(booking.startDate)} - ${formatAnyDate(booking.endDate)}'),
                      Text('Status: ${booking.statusDisplayName}'),
                      Text('Total: ${booking.totalPrice} RWF'),
                    ],
                  ),
                  trailing: booking.status == 'pending'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _updateBookingStatus(booking.id, 'confirmed'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _updateBookingStatus(booking.id, 'cancelled'),
                            ),
                          ],
                        )
                      : null,
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  void _updateBookingStatus(String bookingId, String status) async {
    try {
      await BookingStore.updateBookingStatus(bookingId, status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking ${status} successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update booking: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAFC),
        appBar: AppBar(
          title: const Text(
            'Admin Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF667eea),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.analytics),
              tooltip: 'Analytics',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminAnalyticsScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () {
                UserStore.logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Users', icon: Icon(Icons.people)),
              Tab(text: 'Cars', icon: Icon(Icons.directions_car)),
              Tab(text: 'Bookings', icon: Icon(Icons.book_online)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUsersTab(),
            _buildCarManagementTab(),
            _buildBookingsTab(),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final tabController = DefaultTabController.of(context);
            if (tabController?.index == 0) {
              return FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UserManagementScreen()),
                  );
                },
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.person_add),
                label: const Text('Add User'),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        // Statistics Cards
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: StreamBuilder<int>(
                  stream: UserStore.getTotalUsersCountStream(),
                  builder: (context, snapshot) {
                    return _buildStatCard(
                      'Total Users',
                      (snapshot.data ?? 0).toString(),
                      Icons.people,
                      Colors.blue,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StreamBuilder<int>(
                  stream: UserStore.getActiveUsersCountStream(),
                  builder: (context, snapshot) {
                    return _buildStatCard(
                      'Active Users',
                      (snapshot.data ?? 0).toString(),
                      Icons.check_circle,
                      Colors.green,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StreamBuilder<int>(
                  stream: UserStore.getAdminCountStream(),
                  builder: (context, snapshot) {
                    return _buildStatCard(
                      'Admins',
                      (snapshot.data ?? 0).toString(),
                      Icons.admin_panel_settings,
                      Colors.purple,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Revenue Card
              Expanded(
                child: StreamBuilder<Map<String, int>>(
                  stream: BookingStore.getRevenueStatisticsStream(),
                  builder: (context, snapshot) {
                    final revenue = snapshot.data != null ? snapshot.data!["confirmed"] ?? 0 : 0;
                    return _buildStatCard(
                      'Revenue',
                      '$revenue RWF',
                      Icons.attach_money,
                      Colors.teal,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StreamBuilder<List<Car>>(
                  stream: CarStore.getCarsStream(),
                  builder: (context, snapshot) {
                    return _buildStatCard(
                      'Cars',
                      (snapshot.data?.length ?? 0).toString(),
                      Icons.directions_car,
                      Colors.orange,
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Users List
        Expanded(
          child: StreamBuilder<List<User>>(
            stream: _searchQuery.isEmpty 
                ? UserStore.getAllUsersStream()
                : UserStore.searchUsersStream(_searchQuery),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              
              final users = snapshot.data ?? [];
              
              if (users.isEmpty) {
                return const Center(
                  child: Text(
                    'No users found',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _buildUserCard(user);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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

  Widget _buildUserCard(User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isAdmin ? Colors.purple : Colors.blue,
          child: Text(
            user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            Text(
              'Role: ${user.roleDisplayName}',
              style: TextStyle(
                color: user.isAdmin ? Colors.purple : Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Status: ${user.isActive ? "Active" : "Inactive"}',
              style: TextStyle(
                color: user.isActive ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text('Last Login: ${user.formattedLastLogin}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'toggle_status':
                _onUserStatusChanged(user, !user.isActive);
                break;
              case 'delete':
                _showDeleteConfirmation(user);
                break;
              case 'edit':
                _showEditUserDialog(user);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle_status',
              child: Row(
                children: [
                  Icon(
                    user.isActive ? Icons.block : Icons.check_circle,
                    color: user.isActive ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(user.isActive ? 'Deactivate' : 'Activate'),
                ],
              ),
            ),
            if (!user.isAdmin) PopupMenuItem(
              value: 'edit',
              child: const Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            if (!user.isAdmin && user.id != UserStore.currentUser?.id) PopupMenuItem(
              value: 'delete',
              child: const Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  void _showDeleteConfirmation(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _onUserDeleted(user.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(User user) {
    // This would open a dialog to edit user details
    // For now, just show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit user functionality coming soon!')),
    );
  }
} 
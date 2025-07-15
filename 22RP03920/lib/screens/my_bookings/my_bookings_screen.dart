import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    try {
      await _firestoreService.updateAppointmentStatus(
          appointmentId, 'cancelled');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment cancelled successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to cancel appointment: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.getCurrentUser();
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Bookings')),
        body: const Center(child: Text('Please log in to see your bookings.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('My Bookings'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getAppointmentsForUser(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong fetching appointments.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allAppointments = snapshot.data!.docs;
          final now = DateTime.now();

          final upcomingAppointments = allAppointments.where((doc) {
            final apt = doc.data() as Map<String, dynamic>;
            final status = apt['status'] ?? '';
            final dateStr = apt['date'] ?? '';
            final timeStr = apt['timeSlot'] ?? '';
            DateTime? aptDateTime;
            try {
              if (dateStr.isNotEmpty && timeStr.isNotEmpty) {
                final dateParts = dateStr.split('-');
                final timeParts = timeStr.split(':');
                if (dateParts.length == 3 && timeParts.length >= 2) {
                  aptDateTime = DateTime(
                    int.parse(dateParts[0]),
                    int.parse(dateParts[1]),
                    int.parse(dateParts[2]),
                    int.parse(timeParts[0]),
                    int.parse(timeParts[1]),
                  );
                }
              }
            } catch (_) {}
            return (status == 'approved' || status == 'confirmed') && aptDateTime != null && aptDateTime.isAfter(now);
          }).toList();

          final completedAppointments = allAppointments.where((doc) {
            final apt = doc.data() as Map<String, dynamic>;
            final status = apt['status'] ?? '';
            final dateStr = apt['date'] ?? '';
            final timeStr = apt['timeSlot'] ?? '';
            DateTime? aptDateTime;
            try {
              if (dateStr.isNotEmpty && timeStr.isNotEmpty) {
                final dateParts = dateStr.split('-');
                final timeParts = timeStr.split(':');
                if (dateParts.length == 3 && timeParts.length >= 2) {
                  aptDateTime = DateTime(
                    int.parse(dateParts[0]),
                    int.parse(dateParts[1]),
                    int.parse(dateParts[2]),
                    int.parse(timeParts[0]),
                    int.parse(timeParts[1]),
                  );
                }
              }
            } catch (_) {}
            return status == 'completed' || ((status == 'approved' || status == 'confirmed') && aptDateTime != null && aptDateTime.isBefore(now));
          }).toList();

          final cancelledAppointments = allAppointments.where((doc) {
            final apt = doc.data() as Map<String, dynamic>;
            final status = apt['status'] ?? '';
            return status == 'cancelled' || status == 'rejected';
          }).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _AppointmentsList(
                appointments: upcomingAppointments,
                onCancel: _cancelAppointment,
                showCancelButton: true,
              ),
              _AppointmentsList(
                appointments: completedAppointments,
                onCancel: _cancelAppointment,
                showCancelButton: false,
              ),
              _AppointmentsList(
                appointments: cancelledAppointments,
                onCancel: _cancelAppointment,
                showCancelButton: false,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AppointmentsList extends StatelessWidget {
  final List<DocumentSnapshot> appointments;
  final Function(String) onCancel;
  final bool showCancelButton;

  const _AppointmentsList({
    Key? key,
    required this.appointments,
    required this.onCancel,
    required this.showCancelButton,
  }) : super(key: key);

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No appointments found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const Text(
              'Book your first appointment with a doctor',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/doctors'),
              child: const Text('Find Doctors'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointmentData =
            appointments[index].data() as Map<String, dynamic>;
        final appointmentId = appointments[index].id;
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      appointmentData['specialty'] ?? 'Specialty',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(appointmentData['status'] ?? ''),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        appointmentData['status']?.toUpperCase() ?? 'N/A',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  appointmentData['doctorName'] ?? 'Doctor Name',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  appointmentData['location'] ?? 'Location',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(_formatDate(appointmentData['date'] ?? '')),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(appointmentData['timeSlot'] ?? ''),
                  ],
                ),
                if (showCancelButton &&
                    (appointmentData['status'] == 'pending' ||
                        appointmentData['status'] == 'confirmed'))
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => onCancel(appointmentId),
                      child: const Text('Cancel Appointment',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
} 
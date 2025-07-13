import 'package:flutter/material.dart';

class BookingConfirmationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final booking = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (booking == null) {
      return Scaffold(
        body: Center(child: Text('No booking data provided!')),
      );
    }

    final carName = booking['carName'] ?? booking['car'] ?? '';
    final carImage = booking['carImage'] ?? '';
    final date = booking['date'] ?? '';
    final time = booking['time'] ?? '';
    final withDriver = booking['withDriver'] == true;
    final withDecoration = booking['withDecoration'] == true;
    final specialRequest = booking['specialRequest'] ?? '';
    final status = booking['status'] ?? 'PENDING';
    final isConfirmed = status == 'CONFIRMED';
    final isCancelled = status == 'CANCELLED';
    final statusColor = isConfirmed ? theme.colorScheme.secondary : isCancelled ? theme.colorScheme.error : theme.colorScheme.primary;
    final statusText = isConfirmed ? 'Booking Confirmed!' : isCancelled ? 'Booking Cancelled' : 'Booking Pending';
    final statusTitle = isConfirmed ? 'Booking Confirmed' : isCancelled ? 'Booking Cancelled' : 'Booking Pending';
    final icon = isConfirmed ? Icons.check_circle : isCancelled ? Icons.cancel : Icons.hourglass_empty;

    String message;
    if (isConfirmed) {
      message = 'Your $carName is reserved for $date at $time.';
    } else if (isCancelled) {
      message = 'Your booking for $carName on $date at $time has been cancelled.';
    } else {
      message = 'Your booking for $carName is pending for $date at $time.';
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/available_cars_screen',
              (route) => false,
            );
          },
        ),
        title: Text(statusTitle),
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Icon(icon, color: statusColor, size: 64),
            const SizedBox(height: 16),
            Text(statusTitle, style: theme.textTheme.displayMedium?.copyWith(color: statusColor)),
            const SizedBox(height: 8),
            Text(statusText, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (carImage.isNotEmpty)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: carImage.toString().startsWith('http')
                            ? Image.network(carImage, height: 120, width: 200, fit: BoxFit.cover)
                            : Image.asset(carImage, height: 120, width: 200, fit: BoxFit.cover),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text('Car: $carName', style: theme.textTheme.bodyLarge),
                    Text('Date: $date', style: theme.textTheme.bodyLarge),
                    Text('Time: $time', style: theme.textTheme.bodyLarge),
                    Text('With Driver: ${withDriver ? 'Yes' : 'No'}', style: theme.textTheme.bodyLarge),
                    Text('With Decoration: ${withDecoration ? 'Yes' : 'No'}', style: theme.textTheme.bodyLarge),
                    if (specialRequest.isNotEmpty)
                      Text('Special Request: $specialRequest', style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 12),
                    Divider(),
                    Text('Booking ID: ${booking['id'] ?? '#BK2024-001'}', style: theme.textTheme.bodyMedium),
                    Text('Status: $status', style: theme.textTheme.bodyMedium),
                    if (isCancelled && booking['cancellationReason'] != null && booking['cancellationReason'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('Cancellation Reason: ${booking['cancellationReason']}', style: TextStyle(color: theme.colorScheme.error)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: const Text('View in My Bookings'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 2,
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/my_bookings_screen');
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Download Receipt'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                onPressed: () {},
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
        onDestinationSelected: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, '/available_cars_screen');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/profile');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/my_bookings_screen');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          NavigationDestination(icon: Icon(Icons.calendar_today), label: 'Bookings'),
        ],
        height: 70,
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.colorScheme.secondary.withOpacity(0.1),
      ),
    );
  }
} 
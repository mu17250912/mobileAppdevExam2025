import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/messaging_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../models/booking_model.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';
import '../messaging/chat_screen.dart';
import '../notification/notification_screen.dart';
import '../payment/payment_history_screen.dart';
import '../subscription/subscription_details_screen.dart';

class ProviderDashboard extends StatelessWidget {
  const ProviderDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bookingProvider = Provider.of<BookingProvider>(context);
    final messagingProvider = Provider.of<MessagingProvider>(context);
    final paymentProvider = Provider.of<PaymentProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final user = authProvider.userData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              // Go to profile
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileSummary(user),
          const SizedBox(height: 16),
          _buildEarningsSummary(paymentProvider),
          const SizedBox(height: 16),
          _buildBookingRequests(bookingProvider),
          const SizedBox(height: 16),
          _buildRecentMessages(messagingProvider),
          const SizedBox(height: 16),
          _buildQuickLinks(context),
        ],
      ),
    );
  }

  Widget _buildProfileSummary(UserModel? user) {
    if (user == null) return const SizedBox.shrink();
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user.profileImage != null && user.profileImage!.isNotEmpty
              ? NetworkImage(user.profileImage!)
              : null,
          child: (user.profileImage == null || user.profileImage!.isEmpty)
              ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U')
              : null,
        ),
        title: Text(user.name),
        subtitle: Text(user.email),
        trailing: user.isPremium
            ? const Chip(label: Text('Premium'), backgroundColor: Colors.amber)
            : null,
      ),
    );
  }

  Widget _buildEarningsSummary(PaymentProvider paymentProvider) {
    // For demo, just show count and sum
    final total = paymentProvider.payments.fold<double>(0, (sum, p) => sum + (p.amount ?? 0));
    return Card(
      child: ListTile(
        leading: const Icon(Icons.attach_money, size: 32),
        title: const Text('Earnings'),
        subtitle: Text('Total: ${total.toStringAsFixed(2)} RWF'),
        trailing: IconButton(
          icon: const Icon(Icons.history),
          onPressed: () {}, // Link to payment history
        ),
      ),
    );
  }

  Widget _buildBookingRequests(BookingProvider bookingProvider) {
    final requests = bookingProvider.bookings.where((b) => b.status == AppConstants.bookingPending).toList();
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.event_available),
        title: const Text('Booking Requests'),
        subtitle: Text('${requests.length} pending'),
        children: requests.isEmpty
            ? [const ListTile(title: Text('No pending requests'))]
            : requests.map((booking) => ListTile(
                title: Text(booking.fullName ?? 'Unknown'),
                subtitle: Text('Event: ${booking.eventId}\n${booking.preferredDate ?? ''}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () {
                        bookingProvider.updateBookingStatus(booking.id, AppConstants.bookingConfirmed);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        bookingProvider.updateBookingStatus(booking.id, AppConstants.bookingCancelled);
                      },
                    ),
                  ],
                ),
              )).toList(),
      ),
    );
  }

  Widget _buildRecentMessages(MessagingProvider messagingProvider) {
    final chats = messagingProvider.chats.take(3).toList();
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.chat),
        title: const Text('Recent Messages'),
        subtitle: Text('${chats.length} conversations'),
        children: chats.isEmpty
            ? [const ListTile(title: Text('No recent messages'))]
            : chats.map((chat) => ListTile(
                title: Text(messagingProvider.getOtherParticipantName(chat.id)),
                subtitle: Text(chat.lastMessage.isNotEmpty ? chat.lastMessage : 'No messages yet'),
                trailing: chat.unreadCounts[messagingProvider.currentUserId] != null && chat.unreadCounts[messagingProvider.currentUserId]! > 0
                    ? CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.red,
                        child: Text(
                          chat.unreadCounts[messagingProvider.currentUserId].toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      )
                    : null,
                onTap: () {
                  // Open chat
                },
              )).toList(),
      ),
    );
  }

  Widget _buildQuickLinks(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.account_circle),
          label: const Text('Profile'),
          onPressed: () {},
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.payment),
          label: const Text('Payments'),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()));
          },
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.star),
          label: const Text('Subscription'),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionDetailsScreen()));
          },
        ),
      ],
    );
  }
} 
import 'package:flutter/material.dart';
import 'event_form_screen.dart';
import 'organizer_event_list_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'sign_in_screen.dart';
import 'organizer_tickets_screen.dart';
// import 'event_list_screen.dart';

class OrganizerHomeScreen extends StatelessWidget {
  const OrganizerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Pass the actual organizerId from auth
    final organizerId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizer Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await AuthService().signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EventFormScreen(organizerId: organizerId),
                  ),
                );
              },
              child: const Text('Create New Event'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OrganizerEventListScreen(organizerId: organizerId),
                  ),
                );
              },
              child: const Text('View My Events'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const OrganizerTicketsScreen(),
                  ),
                );
              },
              child: const Text('View All Tickets'),
            ),
          ],
        ),
      ),
    );
  }
} 
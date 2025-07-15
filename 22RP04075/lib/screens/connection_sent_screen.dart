import 'package:flutter/material.dart';

class ConnectionSentScreen extends StatefulWidget {
  @override
  State<ConnectionSentScreen> createState() => _ConnectionSentScreenState();
}

class _ConnectionSentScreenState extends State<ConnectionSentScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final partner = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Connection Successful!'),
          content: Text('You are now connected with ${partner?['name'] ?? 'your partner'}.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Thank You!'),
                    content: Text('Thank you for joining. Have a great session!'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                        },
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final partner = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Connection Sent', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 80),
                  SizedBox(height: 12),
                  Text('Request Sent! 🎉', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                    'Your connection request has been sent to ${partner?['name'] ?? 'your partner'}. You\'ll be notified once they respond.',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(child: Text(partner != null ? (partner['name'] as String).split(' ').map((e) => e[0]).join() : '??'), radius: 24),
                        SizedBox(height: 8),
                        Text(partner?['name'] ?? 'Partner', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${partner?['status'] ?? ''}'),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: (partner?['subjects'] as List?)?.map((subject) => _subjectChip(subject)).toList() ?? [],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              // Already on Partner
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/update-profile');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/join-session');
              break;
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Partner'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Session'),
        ],
      ),
    );
  }

  Widget _subjectChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blueGrey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label),
    );
  }
} 
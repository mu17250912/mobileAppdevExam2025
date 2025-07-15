import 'package:flutter/material.dart';
import '../services/bmi_firebase_service.dart';
import 'login_screen.dart';

class UserBMIRecordsScreen extends StatelessWidget {
  const UserBMIRecordsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userId = LoginScreen.loggedInUserId ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Raw BMI Records'),
        backgroundColor: Colors.indigo[400],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: BMIFirebaseService().getUserBMIRecordsRaw(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading raw Firestore data'));
          }
          final rawEntries = snapshot.data ?? [];
          if (rawEntries.isEmpty) {
            return const Center(child: Text('No raw Firestore records found.', style: TextStyle(fontSize: 16)));
          }
          return ListView.builder(
            itemCount: rawEntries.length,
            itemBuilder: (context, index) {
              final record = rawEntries[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text('BMI: ${record['bmi'] ?? '-'}'),
                  subtitle: Text('Date: ${record['date'] ?? '-'} | Category: ${record['category'] ?? '-'}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 
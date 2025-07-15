import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'join_session_screen.dart';

class PartnerProfileScreen extends StatelessWidget {
  final Map<String, dynamic> partner;

  const PartnerProfileScreen({required this.partner, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAD3D3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 32, width: 32, errorBuilder: (_, __, ___) => SizedBox()),
            SizedBox(width: 8),
            Text('StudySync', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name:  ${partner['name'] ?? ''}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('Status:  ${partner['status'] ?? ''}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Subjects:  ${(partner['subjects'] as List?)?.join(', ') ?? ''}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Sessions:  ${partner['sessions'] ?? ''}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Rating:  ${partner['rating'] ?? ''}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Partners:  ${partner['partners'] ?? ''}', style: TextStyle(fontSize: 16)),
            Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[100],
                    foregroundColor: Colors.deepPurple,
                    padding: EdgeInsets.symmetric(vertical: 18),
                    shape: StadiumBorder(),
                    textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JoinSessionScreen(partner: partner),
                      ),
                    );
                  },
                  child: Text('Join Session'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
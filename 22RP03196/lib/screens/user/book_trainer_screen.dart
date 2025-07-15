import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class BookTrainerScreen extends StatefulWidget {
  const BookTrainerScreen({super.key});

  @override
  State<BookTrainerScreen> createState() => _BookTrainerScreenState();
}

class _BookTrainerScreenState extends State<BookTrainerScreen> {
  final _sessionFeeController = TextEditingController(text: '50');
  bool _loading = false;
  String _selectedTrainerId = 'trainer123';
  final List<Map<String, String>> _trainers = [
    {'id': 'trainer123', 'name': 'Alex Johnson'},
    {'id': 'trainer456', 'name': 'Maria Lopez'},
    {'id': 'trainer789', 'name': 'Sam Patel'},
  ];

  Future<void> _bookSession(String userId, String userEmail) async {
    setState(() => _loading = true);
    try {
      final sessionFee = double.tryParse(_sessionFeeController.text) ?? 50.0;
      final commission = sessionFee * 0.1;
      final trainer = _trainers.firstWhere((t) => t['id'] == _selectedTrainerId);
      await FirebaseFirestore.instance.collection('commissions').add({
        'userId': userId,
        'userEmail': userEmail,
        'trainerId': trainer['id'],
        'trainerName': trainer['name'],
        'sessionFee': sessionFee,
        'commission': commission,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Session booked with ${trainer['name']}! Commission: 24${commission.toStringAsFixed(2)}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().user,
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(
            backgroundColor: const Color(0xFF22A6F2),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data!;
        return Scaffold(
          backgroundColor: const Color(0xFF22A6F2),
          appBar: AppBar(
            backgroundColor: const Color(0xFF22A6F2),
            elevation: 0,
            title: Text('Book a Trainer', style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center, color: Colors.white, size: 80),
                  SizedBox(height: 24),
                  Text('Book a Session', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    value: _selectedTrainerId,
                    items: _trainers.map((trainer) {
                      return DropdownMenuItem<String>(
                        value: trainer['id'],
                        child: Text(trainer['name']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTrainerId = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Select Trainer',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _sessionFeeController,
                    decoration: InputDecoration(
                      hintText: 'Session Fee',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : () => _bookSession(user.uid, user.email),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF22A6F2),
                      minimumSize: Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      textStyle: TextStyle(fontSize: 18),
                      elevation: 2,
                    ),
                    child: _loading ? CircularProgressIndicator() : Text('Book Now', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateSessionScreen extends StatefulWidget {
  @override
  _CreateSessionScreenState createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _goalsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String sessionType = 'Virtual'; // default
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay(hour: 14, minute: 0);

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMM dd, yyyy').format(selectedDate);
    final formattedTime = selectedTime.format(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Create Session', style: TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Session Title'),
              TextFormField(
                controller: _titleController,
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter a session title' : null,
                decoration: InputDecoration(
                  hintText: 'e.g. Calculus Study Group',
                  filled: true,
                  fillColor: Colors.blueGrey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
              SizedBox(height: 20),
              _sectionLabel('Description'),
              TextFormField(
                controller: _descriptionController,
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter a description' : null,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'What you’ll be studying and hoping to achieve...',
                  filled: true,
                  fillColor: Colors.blueGrey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
              SizedBox(height: 20),
              _sectionLabel('Set Goals'),
              TextFormField(
                controller: _goalsController,
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter goals for the session' : null,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'e.g. Complete 3 chapters, solve 10 problems, etc.',
                  filled: true,
                  fillColor: Colors.blueGrey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
              SizedBox(height: 20),
              _sectionLabel('Session Type'),
              SizedBox(height: 10),
              Row(
                children: [
                  _typeToggleButton('Virtual', Icons.computer),
                  SizedBox(width: 12),
                  _typeToggleButton('In-Person', Icons.location_on),
                ],
              ),
              SizedBox(height: 20),
              _sectionLabel('Date & Time'),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _dateTimeBox(formattedDate, Icons.calendar_today, _pickDate),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _dateTimeBox(formattedTime, Icons.access_time, _pickTime),
                  ),
                ],
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: _isLoading ? null : () async {
                    if (!(_formKey.currentState?.validate() ?? false)) return;
                    setState(() => _isLoading = true);
                    final title = _titleController.text.trim();
                    final description = _descriptionController.text.trim();
                    final goals = _goalsController.text.trim();
                    final date = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );
                    // Check for duplicate
                    final existing = await FirebaseFirestore.instance
                      .collection('sessions')
                      .where('title', isEqualTo: title)
                      .where('description', isEqualTo: description)
                      .where('date', isEqualTo: date.toIso8601String())
                      .get();
                    if (existing.docs.isNotEmpty) {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('A session with this title, description, and date already exists.')),
                      );
                      return;
                    }
                    await FirebaseFirestore.instance.collection('sessions').add({
                      'title': title,
                      'description': description,
                      'goals': goals,
                      'type': sessionType,
                      'date': date.toIso8601String(),
                      'createdAt': DateTime.now(),
                      'participants': [],
                    });
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Session Created!')),
                    );
                    Navigator.pushReplacementNamed(context, '/find-partner');
                  },
                  child: _isLoading
                      ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Submit', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey[600],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/find-partner');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/update-profile');
              break;
            case 3:
              // Already on Session
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Partner'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Session'),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600));
  }

  Widget _styledTextField(TextEditingController controller, String hint, {int lines = 1}) {
    return TextField(
      controller: controller,
      maxLines: lines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.blueGrey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.all(16),
      ),
    );
  }

  Widget _typeToggleButton(String type, IconData icon) {
    final bool isSelected = sessionType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            sessionType = type;
          });
        },
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[700] : Colors.blueGrey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.black),
              SizedBox(height: 4),
              Text(
                type,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateTimeBox(String text, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.blueGrey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            SizedBox(width: 8),
            Text(text, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

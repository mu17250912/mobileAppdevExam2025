import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TakeAttendanceScreen extends StatefulWidget {
  const TakeAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  String? _selectedStudentId;
  String? _selectedStudentName;
  String? _selectedCourse;
  String? _status;
  bool _isLoading = false;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  void _fetchStudents() async {
    final snapshot = await FirebaseFirestore.instance.collection('students').orderBy('name').get();
    setState(() {
      _students = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'studentId': data['studentId'],
          'name': data['name'],
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take Attendance'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Student Name Dropdown
            DropdownButtonFormField<String>(
              value: _students.any((s) => s['name'] == _selectedStudentName) ? _selectedStudentName : null,
              decoration: const InputDecoration(
                labelText: 'Student Name',
                border: OutlineInputBorder(),
              ),
              items: _students.map((student) {
                return DropdownMenuItem<String>(
                  value: student['name'],
                  child: Text(student['name'] ?? ''),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedStudentName = val;
                  final match = _students.firstWhere((s) => s['name'] == val, orElse: () => {});
                  _selectedStudentId = match['studentId'];
                });
              },
            ),
            const SizedBox(height: 16),
            // Student ID Dropdown
            DropdownButtonFormField<String>(
              value: _students.any((s) => s['studentId'] == _selectedStudentId) ? _selectedStudentId : null,
              decoration: const InputDecoration(
                labelText: 'Student ID',
                border: OutlineInputBorder(),
              ),
              items: _students.map((student) {
                return DropdownMenuItem<String>(
                  value: student['studentId'],
                  child: Text(student['studentId'] ?? ''),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedStudentId = val;
                  final match = _students.firstWhere((s) => s['studentId'] == val, orElse: () => {});
                  _selectedStudentName = match['name'];
                });
              },
            ),
            const SizedBox(height: 16),
            // Course Dropdown
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('courses').orderBy('name').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final courses = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  value: _selectedCourse,
                  decoration: const InputDecoration(
                    labelText: 'Course',
                    border: OutlineInputBorder(),
                  ),
                  items: courses.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(data['name'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCourse = val),
                );
              },
            ),
            const SizedBox(height: 16),
            // Status Radio Buttons
            Row(
              children: [
                const Text('Status:'),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    children: [
                      Radio<String>(
                        value: 'Present',
                        groupValue: _status,
                        onChanged: (val) => setState(() => _status = val),
                      ),
                      const Text('Present'),
                      Radio<String>(
                        value: 'Absent',
                        groupValue: _status,
                        onChanged: (val) => setState(() => _status = val),
                      ),
                      const Text('Absent'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_selectedStudentId == null || _selectedStudentName == null || _selectedCourse == null || _status == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select student, course, and status.')),
                          );
                          return;
                        }
                        setState(() => _isLoading = true);
                        try {
                          await FirebaseFirestore.instance.collection('attendance').add({
                            'studentId': _selectedStudentId,
                            'studentName': _selectedStudentName,
                            'courseId': _selectedCourse,
                            'status': _status,
                            'timestamp': FieldValue.serverTimestamp(),
                          });
                          setState(() {
                            _selectedStudentId = null;
                            _selectedStudentName = null;
                            _selectedCourse = null;
                            _status = null;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Attendance recorded!')),
                          );
                          Navigator.pushReplacementNamed(context, '/admin_dashboard');
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: ${e.toString()}')),
                          );
                        }
                        setState(() => _isLoading = false);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendanceScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const AttendanceScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Map<String, dynamic>> _students = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, String> _attendanceStatus = {};
  int _tabIndex = 0; // 0 = Mark, 1 = History
  
  // Statistics
  int _presentCount = 0;
  int _absentCount = 0;
  int _lateCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final studentsQuery = await FirebaseFirestore.instance
          .collection('students')
          .orderBy('name')
          .get();

      final students = studentsQuery.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'rollNo': data['rollNo'] ?? '',
          'class': data['class'] ?? '',
        };
      }).toList();

      // Load existing attendance for today if any
      await _loadExistingAttendance();

      setState(() {
        _students = students;
        _isLoading = false;
      });

      _updateStatistics();
    } catch (e) {
      print('Error loading students: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadExistingAttendance() async {
    try {
      final dateStr = _formatDateForFirestore(_selectedDate);
      
      final attendanceQuery = await FirebaseFirestore.instance
          .collection('attendance')
          .where('date', isEqualTo: dateStr)
          .get();

      if (attendanceQuery.docs.isNotEmpty) {
        final attendanceData = attendanceQuery.docs.first.data();
        final students = attendanceData['students'] as List<dynamic>? ?? [];
        
        final statusMap = <String, String>{};
        for (final student in students) {
          statusMap[student['studentId']] = student['status'] ?? 'present';
        }
        
        setState(() {
          _attendanceStatus = statusMap;
        });
      }
    } catch (e) {
      print('Error loading existing attendance: $e');
    }
  }

  String _formatDateForFirestore(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _updateStatistics() {
    int present = 0, absent = 0, late = 0;
    
    for (final student in _students) {
      final status = _attendanceStatus[student['id']] ?? 'present';
      switch (status) {
        case 'present':
          present++;
          break;
        case 'absent':
          absent++;
          break;
        case 'late':
          late++;
          break;
      }
    }

    setState(() {
      _presentCount = present;
      _absentCount = absent;
      _lateCount = late;
    });
  }

  void _markAttendance(String studentId, String status) {
    setState(() {
      _attendanceStatus[studentId] = status;
    });
    _updateStatistics();
  }

  Future<void> _saveAttendance() async {
    if (_students.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final dateStr = _formatDateForFirestore(_selectedDate);
      final teacherId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final teacherName = widget.userData['name'] ?? '';

      // Prepare students data
      final studentsData = _students.map((student) {
        return {
          'studentId': student['id'],
          'name': student['name'],
          'rollNo': student['rollNo'],
          'status': _attendanceStatus[student['id']] ?? 'present',
        };
      }).toList();

      // Check if attendance already exists for this date
      final existingQuery = await FirebaseFirestore.instance
          .collection('attendance')
          .where('date', isEqualTo: dateStr)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        // Update existing attendance
        await existingQuery.docs.first.reference.update({
          'students': studentsData,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': teacherId,
        });
      } else {
        // Create new attendance record
        await FirebaseFirestore.instance.collection('attendance').add({
          'date': dateStr,
          'students': studentsData,
          'teacherId': teacherId,
          'teacherName': teacherName,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance saved successfully for ${_formatDateForDisplay(_selectedDate)}'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error saving attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving attendance: $e'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  String _formatDateForDisplay(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _loadExistingAttendance();
      _updateStatistics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Attendance',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_isLoading && _students.isNotEmpty && _tabIndex == 0)
            IconButton(
              icon: _isSaving 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save, color: Color(0xFF3B82F6)),
              onPressed: _isSaving ? null : _saveAttendance,
            ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() { _tabIndex = 0; });
                      _selectedDate = DateTime.now();
                      _loadStudents();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _tabIndex == 0 ? const Color(0xFF4F46E5) : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        'Mark Attendance',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _tabIndex == 0 ? const Color(0xFF4F46E5) : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() { _tabIndex = 1; });
                      _pickHistoryDate();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _tabIndex == 1 ? const Color(0xFF4F46E5) : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        'View History',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _tabIndex == 1 ? const Color(0xFF4F46E5) : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _tabIndex == 0
                ? _buildMarkAttendanceBody()
                : _buildHistoryBody(),
          ),
        ],
      ),
    );
  }

  Future<void> _pickHistoryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() { _selectedDate = picked; });
      await _loadStudents();
    }
  }

  Widget _buildMarkAttendanceBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header with Date Picker
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Attendance for',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatDateForDisplay(_selectedDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
                  
                  const SizedBox(height: 25),
                  
                  // Attendance Summary
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard('Present', _presentCount.toString(), Colors.green),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildSummaryCard('Absent', _absentCount.toString(), Colors.red),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildSummaryCard('Late', _lateCount.toString(), Colors.orange),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Student List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Students',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        '${_students.length} students',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  ..._students.map((student) => _buildStudentCard(student)).toList(),
                  
                  const SizedBox(height: 30),
                  
                  // Save Button
                  if (_students.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveAttendance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Saving...'),
                              ],
                            )
                          : const Text(
                              'Save Attendance',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                      ),
                    ),
                ],
              ),
            );
  }

  Widget _buildHistoryBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header
          GestureDetector(
            onTap: _pickHistoryDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Attendance History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatDateForDisplay(_selectedDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          // Student List (read-only)
          ..._students.map((student) => _buildHistoryStudentCard(student)).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No students found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Students will appear here once they are\nadded to your class',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                count,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final currentStatus = _attendanceStatus[student['id']] ?? 'present';
    
    Color statusColor = Colors.green;
    String statusText = 'Present';
    
    if (currentStatus == 'absent') {
      statusColor = Colors.red;
      statusText = 'Absent';
    } else if (currentStatus == 'late') {
      statusColor = Colors.orange;
      statusText = 'Late';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: Text(
                student['name'].split(' ').map((e) => e[0]).join(''),
                style: const TextStyle(
                  color: Color(0xFF3B82F6),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 15),
          
          // Student Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  'Roll No: ${student['rollNo']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          
          // Status Buttons
          Row(
            children: [
              _buildStatusButton('Present', Colors.green, currentStatus == 'present', () {
                _markAttendance(student['id'], 'present');
              }),
              const SizedBox(width: 8),
              _buildStatusButton('Late', Colors.orange, currentStatus == 'late', () {
                _markAttendance(student['id'], 'late');
              }),
              const SizedBox(width: 8),
              _buildStatusButton('Absent', Colors.red, currentStatus == 'absent', () {
                _markAttendance(student['id'], 'absent');
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryStudentCard(Map<String, dynamic> student) {
    final currentStatus = _attendanceStatus[student['id']] ?? 'Not Marked';
    Color statusColor = Colors.grey;
    if (currentStatus == 'present') statusColor = Colors.green;
    if (currentStatus == 'absent') statusColor = Colors.red;
    if (currentStatus == 'late') statusColor = Colors.orange;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: Text(
                student['name'].split(' ').map((e) => e[0]).join(''),
                style: const TextStyle(
                  color: Color(0xFF3B82F6),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  'Roll No: ${student['rollNo']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: statusColor,
              ),
            ),
            child: Text(
              currentStatus[0].toUpperCase() + currentStatus.substring(1),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(String text, Color color, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
} 
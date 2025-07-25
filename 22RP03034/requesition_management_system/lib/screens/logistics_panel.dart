import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'request_details_screen.dart';
import 'delivery_confirmation_screen.dart';
import '../models/request_model.dart';
import '../widgets/app_drawer.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class LogisticsPanel extends StatefulWidget {
  const LogisticsPanel({super.key});

  @override
  State<LogisticsPanel> createState() => _LogisticsPanelState();
}

class _LogisticsPanelState extends State<LogisticsPanel> {
  List<Request> _requests = [];
  bool _isLoading = true;
  String _userName = '';
  String _userEmail = '';
  String? _profileImageUrl;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadRequests();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          setState(() {
            _userName = userData['name'] ?? '';
            _userEmail = userData['email'] ?? '';
            _profileImageUrl = userData['profileImage'];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        setState(() {
          _isUploadingImage = true;
        });

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final storageRef = FirebaseStorage.instance.ref().child('profile_images/${user.uid}.jpg');
          await storageRef.putFile(File(pickedFile.path));
          final downloadUrl = await storageRef.getDownloadURL();

          // Update user profile in Firestore
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'profileImage': downloadUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          setState(() {
            _profileImageUrl = downloadUrl;
            _isUploadingImage = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile photo updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  ImageProvider? _getProfileImage() {
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return NetworkImage(_profileImageUrl!);
    }
    return const AssetImage('assets/default_avatar.png');
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('status', whereIn: ['Pending', 'For Approval', 'Approved', 'Delivered'])
          // .orderBy('date', descending: true) // Removed to avoid composite index error
          .get();

      final requests = querySnapshot.docs.map((doc) {
        return Request.fromFirestore(doc.data(), doc.id);
      }).toList();

      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading requests: $e')),
        );
      }
    }
  }

  Future<void> _updateRequestStatus(String requestId, String newStatus, String comment) async {
    try {
      await FirebaseFirestore.instance.collection('requests').doc(requestId).update({
        'status': newStatus,
        'logisticsComment': comment,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add to history
      final request = _requests.firstWhere((r) => r.id == requestId);
      request.addHistory(newStatus, _userName, comment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request status updated to $newStatus')),
        );
        _loadRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  Future<void> _exportToExcel() async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Logistics Report'];

      // Headers
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue('Subject');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = TextCellValue('Employee');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value = TextCellValue('Status');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value = TextCellValue('Date');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).value = TextCellValue('Comment');

      // Data
      for (int i = 0; i < _requests.length; i++) {
        final request = _requests[i];
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1)).value = TextCellValue(request.subject);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1)).value = TextCellValue(request.employeeName);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1)).value = TextCellValue(request.status);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1)).value = TextCellValue(request.date.toString().split(' ')[0]);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 1)).value = TextCellValue(request.logisticsComment ?? '');
      }

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/logistics_report.xlsx');
      await file.writeAsBytes(excel.encode()!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel exported to: ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting Excel: $e')),
        );
      }
    }
  }

  Future<void> _printConfirmedRequests() async {
    final confirmedRequests = _requests.where((r) => r.status == 'Delivered' && r.employeeConfirmed).toList();
    if (confirmedRequests.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No confirmed requests to print.')),
        );
      }
      return;
    }
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Confirmed Delivered Requests Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder.all(),
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.blue100),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Subject', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Employee', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Post', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Quantity', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Logistics Comment', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Approver Comment', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Confirmed', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                ...confirmedRequests.map((r) => pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r.subject)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r.employeeName)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r.postName ?? '')),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r.quantity ?? '')),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r.date.toString().split(' ')[0])),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r.logisticsComment ?? '')),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r.approverComment ?? '')),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Yes')),
                  ],
                )),
              ],
            ),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.blue;
      case 'Delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logistics Panel'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequests,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'print_confirmed') {
                _printConfirmedRequests();
              } else if (value == 'excel') {
                _exportToExcel();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'print_confirmed',
                child: Row(
                  children: [
                    Icon(Icons.print),
                    SizedBox(width: 8),
                    Text('Print Confirmed Requests'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart),
                    SizedBox(width: 8),
                    Text('Export to Excel'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: AppDrawer(
        userName: _userName,
        userEmail: _userEmail,
        profileImageUrl: _profileImageUrl,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Profile Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                                                color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _isUploadingImage ? null : _pickAndUploadImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: _getProfileImage(),
                              onBackgroundImageError: (exception, stackTrace) {
                                debugPrint('Error loading profile image: $exception');
                              },
                            ),
                            if (_isUploadingImage)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                            if (!_isUploadingImage)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userEmail,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Logistics Manager',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Print Confirmed Requests Button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.print),
                      label: const Text('Print Confirmed Requests'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _printConfirmedRequests,
                    ),
                  ),
                ),
                // Content Section
                Expanded(
                  child: _requests.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No requests to manage',
                                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Approved requests will appear here',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadRequests,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadRequests,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _requests.length,
                            itemBuilder: (context, index) {
                              final request = _requests[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  title: Text(
                                    request.subject,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Text('Employee: ${request.employeeName}'),
                                      Text('Date: ${request.date.toString().split(' ')[0]}'),
                                      if (request.logisticsComment != null) ...[
                                        const SizedBox(height: 4),
                                        Text('Comment: ${request.logisticsComment}'),
                                      ],
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(request.status).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              request.status,
                                              style: TextStyle(
                                                color: _getStatusColor(request.status),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (request.status == 'Approved') ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.green,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Text(
                                                  'Confirmed by Approver',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (request.employeeConfirmed) ...[
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'Confirmed by Employee',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'details') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => RequestDetailsScreen(request: request, index: index),
                                          ),
                                        );
                                      } else if (value == 'accept') {
                                        await _updateRequestStatus(request.id, 'For Approval', 'Forwarded to approver by logistics');
                                      } else if (value == 'reject') {
                                        await _updateRequestStatus(request.id, 'Rejected', 'Rejected by logistics');
                                      } else if (value == 'confirm') {
                                        await _updateRequestStatus(request.id, 'Delivered', 'Delivered by logistics');
                                        // Send notification to employee
                                        String? employeeEmail;
                                        final userQuery = await FirebaseFirestore.instance
                                            .collection('users')
                                            .where('name', isEqualTo: request.employeeName)
                                            .limit(1)
                                            .get();
                                        if (userQuery.docs.isNotEmpty) {
                                          employeeEmail = userQuery.docs.first.data()['email'];
                                        }
                                        await FirebaseFirestore.instance.collection('notifications').add({
                                          'title': 'Delivery Completed',
                                          'body': 'Your request "${request.subject}" has been delivered.',
                                          'employeeName': request.employeeName,
                                          'employeeEmail': employeeEmail ?? '',
                                          'timestamp': FieldValue.serverTimestamp(),
                                          'requestId': request.id,
                                          'type': 'delivery_completed',
                                        });
                                      } else if (value == 'view_confirmation') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => DeliveryConfirmationScreen(request: request),
                                          ),
                                        );
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'details',
                                        child: Row(
                                          children: [
                                            Icon(Icons.info),
                                            SizedBox(width: 8),
                                            Text('View Details'),
                                          ],
                                        ),
                                      ),
                                      if (request.status == 'Pending' || request.status == 'For Approval')
                                        const PopupMenuItem(
                                          value: 'accept',
                                          child: Row(
                                            children: [
                                              Icon(Icons.check_circle, color: Colors.green),
                                              SizedBox(width: 8),
                                              Text('Accept', style: TextStyle(color: Colors.green)),
                                            ],
                                          ),
                                        ),
                                      if (request.status == 'Pending' || request.status == 'For Approval')
                                        const PopupMenuItem(
                                          value: 'reject',
                                          child: Row(
                                            children: [
                                              Icon(Icons.cancel, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Reject', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      if (request.status == 'Approved')
                                        const PopupMenuItem(
                                          value: 'confirm',
                                          child: Row(
                                            children: [
                                              Icon(Icons.check_circle),
                                              SizedBox(width: 8),
                                              Text('Mark Delivered'),
                                            ],
                                          ),
                                        ),
                                      if (request.status == 'Delivered' && request.employeeConfirmed)
                                        const PopupMenuItem(
                                          value: 'view_confirmation',
                                          child: Row(
                                            children: [
                                              Icon(Icons.verified),
                                              SizedBox(width: 8),
                                              Text('View Confirmation'),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

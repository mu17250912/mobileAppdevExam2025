import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../services/job_application_service.dart';
import '../services/notification_service.dart';
import '../screens/my_applications_screen.dart';
import '../screens/notifications_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? user;
  late TextEditingController emailController;
  bool isSaving = false;
  bool isLoading = true;
  int unreadNotificationsCount = 0;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final fbUser = fb_auth.FirebaseAuth.instance.currentUser;
      if (fbUser == null) {
        // Not authenticated, redirect to login
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/login');
        });
        return;
      }
      final currentUser = await _userService.getCurrentUserProfile();
      if (currentUser != null) {
        setState(() {
          user = currentUser;
          emailController = TextEditingController(text: currentUser.email);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        // Load unread notifications count
        _loadUnreadNotificationsCount();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User profile not found. Please contact support or re-register.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _loadUnreadNotificationsCount() async {
    if (user == null) return;
    
    try {
      final count = await NotificationService.getUnreadNotificationsCount(user!.id);
      setState(() {
        unreadNotificationsCount = count;
      });
    } catch (e) {
      print('Error loading unread notifications count: $e');
    }
  }

  void _addExperience() async {
    String description = '';
    String? documentName;
    String? documentPath;
    Uint8List? documentBytes;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Experience'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(labelText: 'Description'),
                    onChanged: (val) => description = val,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(documentName == null ? 'No document chosen' : documentName!),
                      ),
                      TextButton(
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform.pickFiles();
                          if (result != null) {
                            setState(() {
                              documentName = result.files.single.name;
                              documentPath = result.files.single.path;
                              documentBytes = result.files.single.bytes;
                            });
                          }
                        },
                        child: Text('Pick Document'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (description.isNotEmpty) {
                      String? downloadUrl;
                      if (documentBytes != null && documentName != null) {
                        final ref = FirebaseStorage.instance.ref().child('experiences/${user!.id}/$documentName');
                        await ref.putData(documentBytes!);
                        downloadUrl = await ref.getDownloadURL();
                      }
                      Navigator.pop(
                        context,
                        Experience(
                          documentName: documentName,
                          documentPath: downloadUrl, // Use Firebase download URL
                          documentBytes: null, // No need to store bytes
                          description: description,
                        ),
                      );
                    }
                  },
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
    ).then((exp) async {
      if (exp != null && exp is Experience) {
        setState(() {
          user!.experiences.add(exp);
        });
        // Save to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user!.id).update({
          'experiences': user!.experiences.map((e) => {
            'description': e.description,
            'documentName': e.documentName,
            'documentPath': e.documentPath, // Firebase Storage URL
          }).toList(),
        });
      }
    });
  }

  void _addToList(String type) async {
    String? value = await showDialog<String>(
      context: context,
      builder: (context) {
        String input = '';
        return AlertDialog(
          title: Text('Add $type'),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(labelText: type),
            onChanged: (val) => input = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, input),
              child: Text('Add'),
            ),
          ],
        );
      },
    );
    if (value != null && value.isNotEmpty) {
      setState(() {
        if (type == 'Degree') {
          user!.degrees.add(value);
        } else if (type == 'Certificate') {
          user!.certificates.add(value);
        }
      });
    }
  }

  // Add this method for general document upload
  void _addDocument() async {
    String? documentName;
    Uint8List? documentBytes;
    String? documentType = 'other';
    bool filePicked = false;
    String? fileError;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Upload Document'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: documentType,
                    items: [
                      DropdownMenuItem(value: 'cv', child: Text('CV')),
                      DropdownMenuItem(value: 'certificate', child: Text('Certificate')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (val) => setState(() => documentType = val),
                    decoration: InputDecoration(labelText: 'Document Type'),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(documentName == null ? 'No document chosen' : documentName!),
                      ),
                      TextButton(
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
                          );
                          if (result != null) {
                            final bytes = result.files.single.bytes;
                            if (bytes != null && bytes.length > 2 * 1024 * 1024) {
                              setState(() {
                                fileError = 'File size must not exceed 2 MB.';
                                documentName = null;
                                documentBytes = null;
                                filePicked = false;
                              });
                            } else {
                              setState(() {
                                documentName = result.files.single.name;
                                documentBytes = bytes;
                                filePicked = true;
                                fileError = null;
                              });
                              print('Picked file: $documentName, size: ${bytes?.length}');
                            }
                          }
                        },
                        child: Text('Pick Document'),
                      ),
                    ],
                  ),
                  if (fileError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(fileError!, style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (filePicked && documentBytes != null && documentName != null && documentType != null)
                      ? () async {
                          print('User: ${user?.id}');
                          print('Uploading: $documentName (${documentBytes!.length} bytes)');
                          final ref = FirebaseStorage.instance.ref().child('documents/${user!.id}/$documentName');
                          print('Firebase ref: ${ref.fullPath}');
                          await ref.putData(documentBytes!);
                          final downloadUrl = await ref.getDownloadURL();
                          print('Download URL: $downloadUrl');
                          Navigator.pop(
                            context,
                            UserDocument(
                              name: documentName!,
                              type: documentType!,
                              url: downloadUrl,
                            ),
                          );
                        }
                      : null,
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    ).then((doc) async {
      if (doc != null && doc is UserDocument) {
        // Save to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user!.id).update({
          'documents': user!.documents.map((d) => d.toMap()).toList(),
        });
        print('Firestore updated for user: ${user!.id}');
        // Re-fetch user profile to get the latest documents
        final updatedUser = await _userService.getCurrentUserProfile();
        setState(() {
          user = updatedUser;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document uploaded!'), backgroundColor: Colors.green),
        );
      }
    });
  }

  // Add certificate upload
  void _uploadCertificate() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && user != null) {
      final fileName = result.files.single.name;
      final fileBytes = result.files.single.bytes;
      if (fileBytes != null) {
        final ref = FirebaseStorage.instance.ref().child('certificates/${user!.id}/${DateTime.now().millisecondsSinceEpoch}_$fileName');
        await ref.putData(fileBytes);
        final downloadUrl = await ref.getDownloadURL();
        setState(() {
          user!.certificates.add(downloadUrl);
        });
        await FirebaseFirestore.instance.collection('users').doc(user!.id).update({
          'certificates': user!.certificates,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Certificate uploaded!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  // Add degree upload
  void _uploadDegree() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && user != null) {
      final fileName = result.files.single.name;
      final fileBytes = result.files.single.bytes;
      if (fileBytes != null) {
        final ref = FirebaseStorage.instance.ref().child('degrees/${user!.id}/${DateTime.now().millisecondsSinceEpoch}_$fileName');
        await ref.putData(fileBytes);
        final downloadUrl = await ref.getDownloadURL();
        setState(() {
          user!.degrees.add(downloadUrl);
        });
        await FirebaseFirestore.instance.collection('users').doc(user!.id).update({
          'degrees': user!.degrees,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Degree uploaded!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  // Add this method to fetch user applications
  Future<List<Map<String, dynamic>>> _fetchUserApplications() async {
    try {
      return await JobApplicationService.getUserApplications(user!.id);
    } catch (e) {
      print('Error fetching user applications: $e');
      return [];
    }
  }

  Future<void> _saveProfile() async {
    if (user == null) return;
    setState(() { isSaving = true; });
    try {
      final fbUser = fb_auth.FirebaseAuth.instance.currentUser;
      if (fbUser != null && emailController.text != user!.email) {
        await fbUser.updateEmail(emailController.text);
      }
      await FirebaseFirestore.instance.collection('users').doc(user!.id).update({
        'email': emailController.text,
      });
      setState(() {
        user = AppUser(
          id: user!.id,
          idNumber: user!.idNumber,
          fullName: user!.fullName,
          telephone: user!.telephone,
          email: emailController.text,
          password: user!.password,
          cvUrl: user!.cvUrl,
          experiences: user!.experiences,
          degrees: user!.degrees,
          certificates: user!.certificates,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() { isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Profile'),
        actions: [
          // Notifications button with badge
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications),
                tooltip: 'Notifications',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsScreen(user: user!),
                    ),
                  ).then((_) {
                    // Reload unread count when returning from notifications
                    _loadUnreadNotificationsCount();
                  });
                },
              ),
              if (unreadNotificationsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadNotificationsCount > 99 ? '99+' : unreadNotificationsCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await fb_auth.FirebaseAuth.instance.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Admin Details Section
              if (user!.email == 'admin@e-recruitment.com')
                Card(
                  color: Colors.blue[50],
                  margin: EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.admin_panel_settings, color: Colors.blue, size: 32),
                            SizedBox(width: 12),
                            Text('Admin Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[900])),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text('Name: ${user!.fullName}', style: TextStyle(fontSize: 16)),
                        Text('Email: ${user!.email}', style: TextStyle(fontSize: 16)),
                        Text('Phone: ${user!.telephone}', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              // Profile Avatar and Name
              CircleAvatar(
                radius: 48,
                backgroundImage: user!.cvUrl != null ? NetworkImage(user!.cvUrl!) : null,
                child: user!.cvUrl == null ? Icon(Icons.person, size: 48) : null,
              ),
              SizedBox(height: 12),
              Text(user!.fullName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(user!.email, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
              SizedBox(height: 16),
              // Personal Info Card
              Card(
                elevation: 2,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Personal Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 8),
                      Text('ID Number: ${user!.idNumber}'),
                      Text('Full Name: ${user!.fullName}'),
                      Text('Telephone: ${user!.telephone}'),
                      Text('Email: ${user!.email}'),
                    ],
                  ),
                ),
              ),
              // Editable Email
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        user!.email,
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              // Expandable Sections
              ExpansionTile(
                title: Text('Education'),
                children: [
                  ...user!.degrees.map((d) => ListTile(title: Text(d))).toList(),
                  TextButton(
                    onPressed: () => _addToList('Degree'),
                    child: Text('Add Degree'),
                  ),
                ],
              ),
              ExpansionTile(
                title: Text('Work Experience'),
                children: [
                  ...user!.experiences.map((e) => ListTile(title: Text(e.description))).toList(),
                  TextButton(
                    onPressed: _addExperience,
                    child: Text('Add Experience'),
                  ),
                ],
              ),
              ExpansionTile(
                title: Text('Certificates'),
                children: [
                  ...user!.certificates.asMap().entries.map((entry) => ListTile(
                        title: Text(entry.value),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.download),
                              onPressed: () async {
                                if (kIsWeb) {
                                  html.AnchorElement anchor = html.AnchorElement(href: entry.value)
                                    ..setAttribute('download', '')
                                    ..target = 'blank';
                                  html.document.body!.append(anchor);
                                  anchor.click();
                                  anchor.remove();
                                } else {
                                  if (await canLaunchUrl(Uri.parse(entry.value))) {
                                    await launchUrl(Uri.parse(entry.value), mode: LaunchMode.externalApplication);
                                  }
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                // Remove from local list
                                setState(() {
                                  user!.certificates.removeAt(entry.key);
                                });
                                // Update Firestore
                                await FirebaseFirestore.instance.collection('users').doc(user!.id).update({
                                  'certificates': user!.certificates,
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Certificate deleted.'), backgroundColor: Colors.red),
                                );
                                // Optionally, delete from Firebase Storage (if you want to clean up storage)
                                // try {
                                //   await FirebaseStorage.instance.refFromURL(entry.value).delete();
                                // } catch (e) {}
                              },
                            ),
                          ],
                        ),
                      )),
                  TextButton(
                    onPressed: () async {
                      String? cert = await showDialog<String>(
                        context: context,
                        builder: (context) {
                          String input = '';
                          return AlertDialog(
                            title: Text('Add Certificate'),
                            content: TextField(
                              autofocus: true,
                              decoration: InputDecoration(labelText: 'Certificate'),
                              onChanged: (val) => input = val,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, input),
                                child: Text('Add'),
                              ),
                            ],
                          );
                        },
                      );
                      if (cert != null && cert.isNotEmpty) {
                        setState(() {
                          user!.certificates.add(cert);
                        });
                        await FirebaseFirestore.instance.collection('users').doc(user!.id).update({
                          'certificates': user!.certificates,
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Certificate added'), backgroundColor: Colors.green),
                        );
                      }
                    },
                    child: Text('Add Certificate'),
                  ),
                ],
              ),
              ExpansionTile(
                title: Text('Documents'),
                children: [
                  Text('Uploaded Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 8),
                  if (user!.documents.isEmpty)
                    Text('No documents uploaded.'),
                  if (user!.documents.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: user!.documents.length,
                      itemBuilder: (context, idx) {
                        final doc = user!.documents[idx];
                        return ListTile(
                          leading: Icon(Icons.insert_drive_file),
                          title: Text(doc.name),
                          subtitle: Text(doc.type),
                          trailing: IconButton(
                            icon: Icon(Icons.download),
                            onPressed: () async {
                              // Open the document URL in browser
                              if (await canLaunchUrl(Uri.parse(doc.url))) {
                                await launchUrl(Uri.parse(doc.url));
                              }
                            },
                          ),
                        );
                      },
                    ),
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: Icon(Icons.upload_file),
                    label: Text('Upload Document'),
                    onPressed: _addDocument,
                  ),
                ],
              ),
              // REMOVE: ExpansionTile for My Applications
              // ExpansionTile(
              //   title: Text('My Applications'),
              //   children: [
              //     FutureBuilder<List<Map<String, dynamic>>>(
              //       future: _fetchUserApplications(),
              //       builder: (context, snapshot) {
              //         if (snapshot.connectionState == ConnectionState.waiting) {
              //           return Center(child: CircularProgressIndicator());
              //         }
              //         if (!snapshot.hasData || snapshot.data!.isEmpty) {
              //           return Column(
              //             children: [
              //               Text('You have not applied to any jobs yet.'),
              //               SizedBox(height: 8),
              //               ElevatedButton.icon(
              //                 icon: Icon(Icons.work),
              //                 label: Text('View All Applications'),
              //                 onPressed: () {
              //                   Navigator.push(
              //                     context,
              //                     MaterialPageRoute(
              //                       builder: (context) => MyApplicationsScreen(user: user!),
              //                     ),
              //                   );
              //                 },
              //               ),
              //             ],
              //           );
              //         }
              //         final apps = snapshot.data!;
              //         return Column(
              //           children: [
              //             ListView.builder(
              //               shrinkWrap: true,
              //               physics: NeverScrollableScrollPhysics(),
              //               itemCount: apps.length > 3 ? 3 : apps.length, // Show only first 3
              //               itemBuilder: (context, idx) {
              //                 final app = apps[idx];
              //                 final status = app['status'] ?? 'pending';
              //                 Color statusColor;
              //                 switch (status) {
              //                   case 'accepted':
              //                     statusColor = Colors.green;
              //                     break;
              //                   case 'rejected':
              //                     statusColor = Colors.red;
              //                     break;
              //                   case 'reviewed':
              //                     statusColor = Colors.orange;
              //                     break;
              //                   default:
              //                     statusColor = Colors.blue;
              //                 }
              //                 return ListTile(
              //                   leading: Icon(Icons.work),
              //                   title: Text(app['jobTitle'] ?? 'Unknown'),
              //                   subtitle: Text('Status: $status', style: TextStyle(color: statusColor)),
              //                   trailing: app['appliedAt'] != null
              //                       ? Text((app['appliedAt'] as Timestamp).toDate().toLocal().toString().split(' ')[0])
              //                       : null,
              //                 );
              //               },
              //             ),
              //             if (apps.length > 3)
              //               Padding(
              //                 padding: EdgeInsets.only(top: 8),
              //                 child: ElevatedButton.icon(
              //                   icon: Icon(Icons.more_horiz),
              //                   label: Text('View All ${apps.length} Applications'),
              //                   onPressed: () {
              //                     Navigator.push(
              //                       context,
              //                       MaterialPageRoute(
              //                         builder: (context) => MyApplicationsScreen(user: user!),
              //                       ),
              //                     );
              //                   },
              //                 ),
              //               ),
              //             SizedBox(height: 8),
              //             ElevatedButton.icon(
              //               icon: Icon(Icons.work),
              //               label: Text('View All Applications'),
              //               onPressed: () {
              //                 Navigator.push(
              //                   context,
              //                   MaterialPageRoute(
              //                     builder: (context) => MyApplicationsScreen(user: user!),
              //                   ),
              //                 );
              //               },
              //             ),
              //           ],
              //         );
              //       },
              //     ),
              //   ],
              // ),
              SizedBox(height: 16),
              
              // Send Details to Admin Section
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.email, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Send Details to Admin',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Not always online? Send your details, CV, certificates, and degrees to admin email so they can find suitable job opportunities for you.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _sendDetailsToAdmin,
                        icon: Icon(Icons.send),
                        label: Text('Send My Details to Admin'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text('Certificates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 8),
              if (user!.certificates.isEmpty)
                Text('No certificates uploaded.'),
              if (user!.certificates.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: user!.certificates.length,
                  itemBuilder: (context, idx) {
                    final url = user!.certificates[idx];
                    return ListTile(
                      leading: Icon(Icons.insert_drive_file),
                      title: Text('Certificate ${idx + 1}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.download),
                            onPressed: () async {
                              if (kIsWeb) {
                                html.AnchorElement anchor = html.AnchorElement(href: url)
                                  ..setAttribute('download', '')
                                  ..target = 'blank';
                                html.document.body!.append(anchor);
                                anchor.click();
                                anchor.remove();
                              } else {
                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                }
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              // Remove from local list
                              setState(() {
                                user!.certificates.removeAt(idx);
                              });
                              // Update Firestore
                              await FirebaseFirestore.instance.collection('users').doc(user!.id).update({
                                'certificates': user!.certificates,
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Certificate deleted.'), backgroundColor: Colors.red),
                              );
                              // Optionally, delete from Firebase Storage (if you want to clean up storage)
                              // try {
                              //   await FirebaseStorage.instance.refFromURL(url).delete();
                              // } catch (e) {}
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              SizedBox(height: 8),
              // Remove Upload Certificate button
              // ElevatedButton.icon(
              //   icon: Icon(Icons.upload_file),
              //   label: Text('Upload Certificate'),
              //   onPressed: _uploadCertificate,
              // ),
              SizedBox(height: 24),
              Text('Degrees', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 8),
              if (user!.degrees.isEmpty)
                Text('No degrees uploaded.'),
              if (user!.degrees.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: user!.degrees.length,
                  itemBuilder: (context, idx) {
                    final url = user!.degrees[idx];
                    return ListTile(
                      leading: Icon(Icons.insert_drive_file),
                      title: Text('Degree ${idx + 1}'),
                      trailing: IconButton(
                        icon: Icon(Icons.download),
                        onPressed: () async {
                          if (kIsWeb) {
                            html.AnchorElement anchor = html.AnchorElement(href: url)
                              ..setAttribute('download', '')
                              ..target = 'blank';
                            html.document.body!.append(anchor);
                            anchor.click();
                            anchor.remove();
                          } else {
                            if (await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
              SizedBox(height: 8),
              // Remove Upload Degree button
              // ElevatedButton.icon(
              //   icon: Icon(Icons.upload_file),
              //   label: Text('Upload Degree'),
              //   onPressed: _uploadDegree,
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendDetailsToAdmin() async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User data not available'), backgroundColor: Colors.red),
      );
      return;
    }

    // Show confirmation dialog about the service fee
    bool? agreed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Service Fee Agreement'),
        content: Text('If you get a job through this service, you agree to pay 20,000 FRW for the service. Do you want to continue and send your details to the admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('I Agree & Continue'),
          ),
        ],
      ),
    );
    if (agreed != true) return;

    try {
      // Save user details to Firestore for admin dashboard
      await FirebaseFirestore.instance.collection('user_submissions').doc(user!.id).set({
        'userId': user!.id,
        'fullName': user!.fullName,
        'telephone': user!.telephone,
        'email': user!.email,
        'cvUrl': user!.cvUrl,
        'degrees': user!.degrees,
        'certificates': user!.certificates,
        'experiences': user!.experiences.map((e) => {
          'description': e.description,
          'documentName': e.documentName,
          'documentPath': e.documentPath,
        }).toList(),
        'submittedAt': Timestamp.now(),
      });

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Preparing your details...'),
            ],
          ),
        ),
      );

      // Prepare email content
      String emailSubject = 'Job Candidate Details - ${user!.fullName}';
      String emailBody = _prepareEmailContent();

      // Create email URL
      String emailUrl = 'mailto:admin@e-recruitment.com?subject=${Uri.encodeComponent(emailSubject)}&body=${Uri.encodeComponent(emailBody)}';

      // Close loading dialog
      Navigator.pop(context);

      // Launch email client
      if (await canLaunchUrl(Uri.parse(emailUrl))) {
        await launchUrl(Uri.parse(emailUrl));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email client opened with your details and sent to admin dashboard'),
                SizedBox(height: 4),
                Text(
                  '📧 Please check your email carefully for responses from employers.',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            duration: Duration(seconds: 6),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Could not open email client. Your details were still sent to admin dashboard.'),
                SizedBox(height: 4),
                Text(
                  '📧 Please check your email carefully for responses from employers.',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            duration: Duration(seconds: 6),
            backgroundColor: Colors.orange,
          ),
        );
        
        // Show details in dialog for manual copying
        _showDetailsDialog(emailBody);
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error preparing details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _prepareEmailContent() {
    String content = '''
Dear Admin,

Please find below my details for job opportunities:

PERSONAL INFORMATION:
Name: ${user!.fullName}
Email: ${user!.email}
Phone: ${user!.telephone}

EXPERIENCE:
${user!.experiences.isNotEmpty ? user!.experiences.map((e) => '- ${e.description}').join('\n') : 'Not provided'}

DOCUMENTS:
CV: ${user!.cvUrl != null ? 'Available' : 'Not uploaded'}
Certificates: ${user!.certificates.length} uploaded
Degrees: ${user!.degrees.length} uploaded

ADDITIONAL INFORMATION:
- I am interested in job opportunities that match my skills and experience
- I am available for interviews and further discussions
- Please contact me at ${user!.email} for any inquiries

Thank you for considering my application.

Best regards,
${user!.fullName}
''';

    return content;
  }

  void _showDetailsDialog(String emailBody) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Your Details for Admin'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email, color: Colors.blue[700], size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '📧 Please check your email carefully for responses from employers.',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Please copy the following details and send them to admin@e-recruitment.com:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  emailBody,
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Copy to clipboard
              // Note: In a real app, you'd use a clipboard package
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Details copied to clipboard')),
              );
              Navigator.pop(context);
            },
            child: Text('Copy to Clipboard'),
          ),
        ],
      ),
    );
  }
} 
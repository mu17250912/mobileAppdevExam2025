import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminSettingsHelp extends StatefulWidget {
  const AdminSettingsHelp({super.key});

  @override
  State<AdminSettingsHelp> createState() => _AdminSettingsHelpState();
}

class _AdminSettingsHelpState extends State<AdminSettingsHelp> {
  final TextEditingController _sportTypeController = TextEditingController();
  final TextEditingController _helpController = TextEditingController();

  Future<void> _loadHelpContent() async {
    final doc = await FirebaseFirestore.instance.collection('settings').doc('help').get();
    _helpController.text = doc.data()?['content'] ?? '';
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadHelpContent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin: Settings & Help', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.deepPurple.shade50, Colors.blue.shade50],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Banner Management Card - Moved to top for prominence
            const AdminBannerUploader(),
            const SizedBox(height: 32),
            // Sports Types Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sports Types', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _sportTypeController,
                            decoration: InputDecoration(
                              hintText: 'Add new sport type',
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            final val = _sportTypeController.text.trim();
                            if (val.isNotEmpty) {
                              await FirebaseFirestore.instance.collection('sports_types').add({'name': val});
                              _sportTypeController.clear();
                              setState(() {});
                            }
                          },
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('sports_types').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        final docs = snapshot.data!.docs;
                        return Column(
                          children: docs.map((doc) {
                            return Card(
                              color: Colors.blue.shade50,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: ListTile(
                                title: Text(doc['name'], style: const TextStyle(color: Colors.deepPurple)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await doc.reference.delete();
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Help Content Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Help Content', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _helpController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Enter help info for users',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () async {
                          await FirebaseFirestore.instance.collection('settings').doc('help').set({'content': _helpController.text});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Help content saved.'), backgroundColor: Colors.deepPurple),
                          );
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Save Help Content', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Social Media & Contact Section
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Connect with Us', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.facebook, size: 32),
                          color: Colors.blue,
                          onPressed: () async {
                            const url = 'https://web.facebook.com/Dwayne.manirakiza.12';
                            if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url));
                          },
                          tooltip: 'Facebook',
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.camera_alt, size: 32), // Instagram alternative
                          color: Colors.purple,
                          onPressed: () async {
                            const url = 'https://www.instagram.com/manirakizadwayne/';
                            if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url));
                          },
                          tooltip: 'Instagram',
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.clear, size: 32), // X (Twitter) alternative
                          color: Colors.black,
                          onPressed: () async {
                            const url = 'https://x.com/manirakizadani7';
                            if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url));
                          },
                          tooltip: 'X',
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.chat, size: 32), // WhatsApp alternative
                          color: Colors.green,
                          onPressed: () => _launchUrl('https://wa.me/250783158697'),
                          tooltip: 'WhatsApp',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.email, color: Colors.deepPurple, size: 18),
                        SizedBox(width: 4),
                        Text('daniel@gmail.com', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 16),
                        Icon(Icons.phone, color: Colors.deepPurple, size: 18),
                        SizedBox(width: 4),
                        Text('+250 783 158 697', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

    );
  }
}

class AdminBannerUploader extends StatefulWidget {
  const AdminBannerUploader({super.key});

  @override
  _AdminBannerUploaderState createState() => _AdminBannerUploaderState();
}

class _AdminBannerUploaderState extends State<AdminBannerUploader> {
  bool _isUploading = false;
  String _uploadStatus = '';

  Future<String?> _uploadToCloudinary({required String filePath, List<int>? fileBytes, required String fileName}) async {
    const cloudName = 'dfmmdkmbu';
    const uploadPreset = 'betting_app';
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    var request = http.MultipartRequest('POST', url);
    request.fields['upload_preset'] = uploadPreset;
    if (fileBytes != null) {
      request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
    } else {
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
    }
    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final data = json.decode(respStr);
      return data['secure_url'];
    } else {
      debugPrint('Cloudinary upload failed: ${response.statusCode}');
      return null;
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      debugPrint('[BannerUpload] Starting image pick/upload. Platform: ${kIsWeb ? 'Web' : 'Mobile/Desktop'}');
      String? imageUrl;
      String fileName = 'banner_${DateTime.now().millisecondsSinceEpoch}.jpg';
      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(type: FileType.image);
        if (result == null || result.files.isEmpty) {
          setState(() => _uploadStatus = 'No image selected / Nta ifoto yatoranijwe');
          debugPrint('[BannerUpload] No image selected.');
          return;
        }
        final fileBytes = result.files.first.bytes;
        if (fileBytes == null) {
          setState(() => _uploadStatus = 'Failed to read file bytes / Kugusoma file byanze');
          debugPrint('[BannerUpload] Failed to read file bytes.');
          return;
        }
        setState(() {
          _isUploading = true;
          _uploadStatus = 'Uploading banner... / Kwakira banner...';
        });
        debugPrint('[BannerUpload] Uploading $fileName (${fileBytes.length} bytes) to Cloudinary...');
        imageUrl = await _uploadToCloudinary(filePath: fileName, fileBytes: fileBytes, fileName: fileName);
      } else {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1200,
          maxHeight: 600,
          imageQuality: 85,
        );
        if (picked == null) {
          setState(() => _uploadStatus = 'No image selected / Nta ifoto yatoranijwe');
          debugPrint('[BannerUpload] No image selected.');
          return;
        }
        setState(() {
          _isUploading = true;
          _uploadStatus = 'Uploading banner... / Kwakira banner...';
        });
        final file = File(picked.path);
        debugPrint('[BannerUpload] Uploading $fileName (${await file.length()} bytes) to Cloudinary...');
        imageUrl = await _uploadToCloudinary(filePath: file.path, fileName: fileName);
      }
      if (imageUrl == null) {
        setState(() {
          _isUploading = false;
          _uploadStatus = 'Cloudinary upload failed / Kwakira kuri Cloudinary byanze';
        });
        debugPrint('[BannerUpload] Cloudinary upload failed');
        return;
      }
      debugPrint('[BannerUpload] Upload complete. Writing to Firestore...');
      try {
        await FirebaseFirestore.instance.collection('ads_banners').add({
          'imageUrl': imageUrl,
          'uploadedAt': FieldValue.serverTimestamp(),
          'fileName': fileName,
        }).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Firestore write timeout / Kwandika kuri Firestore byanze');
          },
        );
        debugPrint('[BannerUpload] Firestore write completed');
      } catch (e) {
        debugPrint('[BannerUpload] Firestore write failed: $e');
        setState(() {
          _isUploading = false;
          _uploadStatus = 'Firestore write failed: $e / Kwandika kuri Firestore byanze: $e';
        });
        return;
      }
      setState(() {
        _isUploading = false;
        _uploadStatus = 'Banner uploaded successfully! / Banner yashyizweho neza!';
      });
      debugPrint('[BannerUpload] Banner uploaded and Firestore updated successfully.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Banner uploaded successfully! / Banner yashyizweho neza!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _uploadStatus = '');
        }
      });
    } catch (e, stack) {
      debugPrint('[BannerUpload] General error: $e');
      debugPrint('[BannerUpload] Stack trace: $stack');
      setState(() {
        _isUploading = false;
        _uploadStatus = 'Upload failed: $e / Kwakira banner byanze: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Upload failed: $e / Kwakira banner byanze: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _uploadStatus = '');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.image, color: Colors.deepPurple, size: 24),
                SizedBox(width: 8),
                Text(
                  'Banner Management',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Upload promotional banners that will be displayed to users on the home screen.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: _isUploading ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                ) : const Icon(Icons.upload),
                label: Text(
                  _isUploading ? 'Uploading...' : 'Upload New Banner',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: _isUploading ? null : _pickAndUploadImage,
              ),
            ),
            if (_uploadStatus.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _uploadStatus.contains('successfully') ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _uploadStatus.contains('successfully') ? Colors.green.shade200 : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _uploadStatus.contains('successfully') ? Icons.check_circle : Icons.info,
                      color: _uploadStatus.contains('successfully') ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _uploadStatus,
                        style: TextStyle(
                          color: _uploadStatus.contains('successfully') ? Colors.green.shade800 : Colors.red.shade800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('ads_banners').orderBy('uploadedAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final banners = snapshot.data!.docs;
                if (banners.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'No banners uploaded yet. Upload your first banner above.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Uploaded Banners (${banners.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurple),
                    ),
                    const SizedBox(height: 8),
                    ...banners.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final imageUrl = data['imageUrl'] as String;
                      final uploadedAt = data['uploadedAt'] as Timestamp?;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: 60,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 60,
                                  height: 40,
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.broken_image, color: Colors.grey),
                                );
                              },
                            ),
                          ),
                          title: Text('Banner ${banners.indexOf(doc) + 1}'),
                          subtitle: uploadedAt != null 
                            ? Text('Uploaded: ${DateFormat('MMM dd, yyyy HH:mm').format(uploadedAt.toDate())}')
                            : const Text('Uploaded recently'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              try {
                                await doc.reference.delete();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Banner deleted successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to delete banner: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 
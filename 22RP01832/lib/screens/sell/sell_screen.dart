import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import '../../models/book.dart';
import '../../providers/book_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';

String sanitizeFileName(String fileName) {
  return fileName.replaceAll(RegExp(r'[\\\[\]#?]'), '_');
}

class SellScreen extends StatefulWidget {
  const SellScreen({Key? key}) : super(key: key);

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _subjectController = TextEditingController();
  XFile? _imageFile;
  PlatformFile? _pdfFile;
  String? _pdfUrl;
  bool _isLoading = false;
  bool _isUploadingPdf = false;
  double _pdfUploadProgress = 0.0;
  String? _webImagePreviewUrl;
  List<String> _subjects = [];
  bool _subjectsLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    final snapshot = await FirebaseFirestore.instance.collection('books').get();
    final allSubjects = snapshot.docs
        .map((doc) => doc['subject'] as String? ?? '')
        .toSet()
        .toList();
    allSubjects.removeWhere((s) => s.trim().isEmpty);
    setState(() {
      _subjects = allSubjects;
      _subjectsLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        final base64Data = base64Encode(bytes);
        setState(() {
          _webImagePreviewUrl = 'data:image/png;base64,$base64Data';
          _imageFile = picked;
        });
      } else {
        setState(() {
          _imageFile = picked;
        });
      }
    }
  }

  Future<String?> _uploadToCloudinary(XFile image) async {
    const cloudName = 'dwavfe9yo';
    const uploadPreset = 'easyrent_unsigned';
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final bytes = await image.readAsBytes();
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: image.name),
      );
    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final data = json.decode(respStr);
      return data['secure_url'];
    } else {
      return null;
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result != null && result.files.single.extension == 'pdf') {
      if (result.files.single.size > 10 * 1024 * 1024) {
        Fluttertoast.showToast(msg: 'PDF must be less than 10MB.');
        return;
      }
      setState(() {
        _pdfFile = result.files.single;
        _isUploadingPdf = true;
      });
      final url = await uploadPdfToCloudinary(_pdfFile!);
      setState(() {
        _isUploadingPdf = false;
      });
      if (url != null) {
        setState(() {
          _pdfUrl = url;
        });
        Fluttertoast.showToast(msg: 'PDF uploaded successfully!');
      } else {
        Fluttertoast.showToast(
          msg: 'PDF upload failed. Check console for details.',
        );
        setState(() {
          _pdfUrl = null;
        });
      }
    }
  }

  Future<String?> uploadPdfToCloudinary(PlatformFile pdf) async {
    final cloudName = 'dwavfe9yo'; // Your Cloudinary cloud name
    final uploadPreset = 'pdf_unsigned'; // Your unsigned upload preset
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/raw/upload',
    );
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes('file', pdf.bytes!, filename: pdf.name),
      );
    try {
      final total = pdf.bytes!.length;
      int sent = 0;
      final stream = http.ByteStream.fromBytes(pdf.bytes!);
      final multipartFile = http.MultipartFile(
        'file',
        stream.transform(
          StreamTransformer.fromHandlers(
            handleData: (data, sink) {
              sent += data.length;
              _pdfUploadProgress = sent.toDouble() / total.toDouble();
              // ignore: invalid_use_of_protected_member
              if (this.mounted) setState(() {});
              sink.add(data);
            },
          ),
        ),
        total,
        filename: pdf.name,
      );
      final progressRequest = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(multipartFile);
      final response = await progressRequest.send();
      final respStr = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final jsonResp = json.decode(respStr);
        _pdfUploadProgress = 0.0;
        if (this.mounted) setState(() {});
        return jsonResp['secure_url'];
      } else {
        _pdfUploadProgress = 0.0;
        if (this.mounted) setState(() {});
        return null;
      }
    } catch (e) {
      _pdfUploadProgress = 0.0;
      if (this.mounted) setState(() {});
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _imageFile == null) {
      Fluttertoast.showToast(
        msg: 'Please fill all fields and select an image.',
      );
      return;
    }
    if (_isUploadingPdf) {
      Fluttertoast.showToast(
        msg: 'Please wait for the PDF to finish uploading.',
      );
      return;
    }
    if (_pdfFile == null || _pdfUrl == null) {
      Fluttertoast.showToast(msg: 'Please select and upload a PDF file.');
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final imageUrl = await _uploadToCloudinary(_imageFile!);
      if (imageUrl == null) {
        Fluttertoast.showToast(msg: 'Image upload failed.');
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Fluttertoast.showToast(msg: 'You must be logged in.');
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final book = Book(
        id: '',
        title: _titleController.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? 0.0,
        description: _descController.text.trim(),
        subject: _subjectController.text.trim(),
        imageUrl: imageUrl,
        sellerId: user.uid,
        status: 'available',
        createdAt: DateTime.now(),
        pdfUrl: _pdfUrl,
      );
      await provider.Provider.of<BookProvider>(
        context,
        listen: false,
      ).addBook(book);
      Fluttertoast.showToast(msg: 'Book listed successfully!');
      _formKey.currentState!.reset();
      setState(() {
        _imageFile = null;
        _pdfFile = null;
        _pdfUrl = null;
        _isLoading = false;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'List a Book',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _pickImage,
                  child: _imageFile == null
                      ? Container(
                          height: 150,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Text('Tap to select image'),
                          ),
                        )
                      : kIsWeb
                      ? (_webImagePreviewUrl != null
                            ? Image.network(
                                _webImagePreviewUrl!,
                                height: 150,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: 150,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Text(
                                    'Image preview not supported on web',
                                  ),
                                ), // fallback
                              ))
                      : Image.file(
                          File(_imageFile!.path),
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickPdf,
                  child: Container(
                    height: 50,
                    color: Colors.grey[100],
                    child: Center(
                      child: Text(
                        _pdfFile == null ? 'Tap to select PDF' : _pdfFile!.name,
                      ),
                    ),
                  ),
                ),
                if (_isUploadingPdf)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 8.0,
                      left: 4.0,
                      right: 4.0,
                    ),
                    child: LinearProgressIndicator(
                      value:
                          _pdfUploadProgress > 0.0 && _pdfUploadProgress < 1.0
                          ? _pdfUploadProgress
                          : null,
                      minHeight: 6,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF9CE800),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Color(0xFF9CE800),
                        width: 2,
                      ),
                    ),
                    labelStyle: TextStyle(color: Colors.black87),
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 16,
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter book title' : null,
                ),
                const SizedBox(height: 16),
                _subjectsLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text == '') {
                            return _subjects;
                          }
                          return _subjects.where((String option) {
                            return option.toLowerCase().contains(
                              textEditingValue.text.toLowerCase(),
                            );
                          });
                        },
                        onSelected: (String selection) {
                          _subjectController.text = selection;
                        },
                        fieldViewBuilder:
                            (context, controller, focusNode, onFieldSubmitted) {
                              controller.text = _subjectController.text;
                              controller.selection = TextSelection.fromPosition(
                                TextPosition(offset: controller.text.length),
                              );
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  labelText: 'Subject',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1.2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1.2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Color(0xFF9CE800),
                                      width: 2,
                                    ),
                                  ),
                                  labelStyle: TextStyle(color: Colors.black87),
                                  hintStyle: TextStyle(color: Colors.grey[500]),
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 18,
                                    horizontal: 16,
                                  ),
                                ),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Enter subject'
                                    : null,
                                onChanged: (v) {
                                  _subjectController.text = v;
                                },
                              );
                            },
                      ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'Price (RWF)',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Color(0xFF9CE800),
                        width: 2,
                      ),
                    ),
                    labelStyle: TextStyle(color: Colors.black87),
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 16,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter price' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Color(0xFF9CE800),
                        width: 2,
                      ),
                    ),
                    labelStyle: TextStyle(color: Colors.black87),
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 16,
                    ),
                  ),
                  maxLines: 3,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter description' : null,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(
                        child: SpinKitWave(color: Color(0xFF9CE800), size: 32),
                      )
                    : ElevatedButton(
                        onPressed: _isUploadingPdf ? null : _submit,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            'List Book',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
 
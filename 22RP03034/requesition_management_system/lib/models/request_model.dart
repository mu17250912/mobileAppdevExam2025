import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class Request {
  String id;
  String subject;
  String description;
  String employeeName;
  String status;
  DateTime date;
  String? quantity;
  String? logisticsComment;
  String? approverComment;
  File? pdfFile;
  int? availableQuantity;
  bool employeeConfirmed;
  String? postName;
  List<Map<String, dynamic>> history;

  Request({
    required this.id,
    required this.subject,
    required this.description,
    required this.employeeName,
    required this.status,
    required this.date,
    this.quantity,
    this.logisticsComment,
    this.approverComment,
    this.pdfFile,
    this.availableQuantity,
    this.employeeConfirmed = false,
    this.postName,
    List<Map<String, dynamic>>? history,
  }) : history = history ?? [];

  factory Request.fromFirestore(Map<String, dynamic> data, String docId) {
    return Request(
      id: docId,
      subject: data['subject'] ?? '',
      description: data['description'] ?? '',
      employeeName: data['employeeName'] ?? '',
      status: data['status'] ?? 'Pending',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      quantity: data['quantity'],
      logisticsComment: data['logisticsComment'],
      approverComment: data['approverComment'],
      // pdfFile cannot be deserialized directly from Firestore
      availableQuantity: data['availableQuantity'],
      employeeConfirmed: data['employeeConfirmed'] ?? false,
      postName: data['postName'],
      history: (data['history'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'description': description,
      'employeeName': employeeName,
      'status': status,
      'date': date,
      'quantity': quantity,
      'logisticsComment': logisticsComment,
      'approverComment': approverComment,
      // pdfFile is not stored in Firestore directly
      'availableQuantity': availableQuantity,
      'employeeConfirmed': employeeConfirmed,
      'postName': postName,
      'history': history,
    };
  }

  void addHistory(String newStatus, String actor, String? comment) {
    history.add({
      'status': newStatus,
      'actor': actor,
      'comment': comment,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}

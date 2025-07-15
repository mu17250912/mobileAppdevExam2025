import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../models/inventory_model.dart';

class HandoverDocumentScreen extends StatefulWidget {
  const HandoverDocumentScreen({super.key});

  @override
  State<HandoverDocumentScreen> createState() => _HandoverDocumentScreenState();
}

class _HandoverDocumentScreenState extends State<HandoverDocumentScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Handover Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _exportAllHandovers(),
          ),
        ],
      ),
      body: InventoryStore.handoverDocuments.isEmpty
          ? const Center(child: Text('No handover documents found.'))
          : ListView.builder(
              itemCount: InventoryStore.handoverDocuments.length,
              itemBuilder: (context, index) {
                final document = InventoryStore.handoverDocuments[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.description, color: Colors.blue),
                    title: Text('Handover: ${document.itemName}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Employee: ${document.employeeName}'),
                        Text('Quantity: ${document.quantity} ${document.unit}'),
                        Text('Date: ${document.handoverDate.toLocal().toString().split(' ')[0]}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility),
                          onPressed: () => _viewHandoverDocument(document),
                        ),
                        IconButton(
                          icon: const Icon(Icons.picture_as_pdf),
                          onPressed: () => _generateHandoverPDF(document),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _viewHandoverDocument(HandoverDocument document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Handover Document'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Item: ${document.itemName}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Category: ${document.itemCategory}'),
              Text('Quantity: ${document.quantity} ${document.unit}'),
              const SizedBox(height: 16),
              Text('Employee: ${document.employeeName}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Post: ${document.employeePost}'),
              const SizedBox(height: 16),
              Text('Logistics: ${document.logisticsName}'),
              Text('Date: ${document.handoverDate.toLocal().toString().split(' ')[0]}'),
              const SizedBox(height: 16),
              const Text('Signatures:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Employee: ${document.employeeSignature}'),
              Text('Logistics: ${document.logisticsSignature}'),
              if (document.notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Notes: ${document.notes}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateHandoverPDF(HandoverDocument document) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'HANDOVER DOCUMENT',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              
              // Item Details
              pw.Text('ITEM DETAILS', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  pw.Text('Item Name: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(document.itemName),
                ],
              ),
              pw.Row(
                children: [
                  pw.Text('Category: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(document.itemCategory),
                ],
              ),
              pw.Row(
                children: [
                  pw.Text('Quantity: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${document.quantity} ${document.unit}'),
                ],
              ),
              pw.SizedBox(height: 20),
              
              // Employee Details
              pw.Text('EMPLOYEE DETAILS', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  pw.Text('Name: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(document.employeeName),
                ],
              ),
              pw.Row(
                children: [
                  pw.Text('Post: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(document.employeePost),
                ],
              ),
              pw.SizedBox(height: 20),
              
              // Handover Details
              pw.Text('HANDOVER DETAILS', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  pw.Text('Date: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(document.handoverDate.toLocal().toString().split(' ')[0]),
                ],
              ),
              pw.Row(
                children: [
                  pw.Text('Logistics: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(document.logisticsName),
                ],
              ),
              pw.SizedBox(height: 30),
              
              // Signatures
              pw.Text('SIGNATURES', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Employee Signature:'),
                      pw.SizedBox(height: 10),
                      pw.Container(
                        width: 150,
                        height: 50,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(),
                        ),
                        child: pw.Center(
                          child: pw.Text(document.employeeSignature),
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Logistics Signature:'),
                      pw.SizedBox(height: 10),
                      pw.Container(
                        width: 150,
                        height: 50,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(),
                        ),
                        child: pw.Center(
                          child: pw.Text(document.logisticsSignature),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (document.notes.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Text('Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(document.notes),
              ],
              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Generated on: ${DateTime.now().toLocal().toString().split('.')[0]}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );
    
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> _exportAllHandovers() async {
    if (InventoryStore.handoverDocuments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No handover documents to export.')),
      );
      return;
    }

    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'ALL HANDOVER DOCUMENTS',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: [
                  'Item', 'Category', 'Quantity', 'Employee', 'Date', 'Logistics'
                ],
                data: InventoryStore.handoverDocuments.map((doc) => [
                  doc.itemName,
                  doc.itemCategory,
                  '${doc.quantity} ${doc.unit}',
                  doc.employeeName,
                  doc.handoverDate.toLocal().toString().split(' ')[0],
                  doc.logisticsName,
                ]).toList(),
                cellStyle: pw.TextStyle(fontSize: 10),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                headerDecoration: pw.BoxDecoration(color: PdfColors.blue100),
              ),
            ],
          );
        },
      ),
    );
    
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
} 
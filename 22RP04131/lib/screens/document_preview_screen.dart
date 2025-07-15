import 'package:flutter/material.dart';
import '../config/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/models.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DocumentPreviewScreen extends StatelessWidget {
  const DocumentPreviewScreen({Key? key, this.document}) : super(key: key);

  final Document? document;

  Future<Uint8List> _generatePdf(Document doc, AppState appState) async {
    final pdf = pw.Document();
    final isPremium = appState.userProfile?.premium ?? false;
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(_docTypeName(doc.type), style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                        pw.Text('#${doc.number}', style: pw.TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('From:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text(appState.userProfile?.businessName ?? appState.userProfile?.name ?? 'Your Business Name'),
                          pw.Text(appState.currentUser?.email ?? 'your@email.com'),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text(doc.clientInfo.name),
                          if (doc.clientInfo.email != null) pw.Text(doc.clientInfo.email!),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 16),
                  pw.Divider(),
                  ...doc.items.map((item) => pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(item.name),
                          pw.Text('RWF ${item.total.toStringAsFixed(2)}'),
                        ],
                      )),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('VAT (${(doc.vatRate * 100).toStringAsFixed(0)}%)'),
                      pw.Text('RWF ${doc.vatAmount.toStringAsFixed(2)}'),
                    ],
                  ),
                  pw.Divider(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('RWF ${doc.total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              if (!isPremium)
                pw.Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: pw.Center(
                    child: pw.Opacity(
                      opacity: 0.2,
                      child: pw.Text(
                        'Created with QuickDocs',
                        style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: PdfColors.grey),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  Future<void> _downloadPdf(BuildContext context, Document doc, AppState appState) async {
    final pdfBytes = await _generatePdf(doc, appState);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_docTypeName(doc.type)}_${doc.number}.pdf');
    await file.writeAsBytes(pdfBytes);
    await Printing.sharePdf(bytes: pdfBytes, filename: '${_docTypeName(doc.type)}_${doc.number}.pdf');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF downloaded and ready to share!')),
    );
  }

  Future<void> _sharePdfWhatsApp(BuildContext context, Document doc, AppState appState) async {
    final pdfBytes = await _generatePdf(doc, appState);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_docTypeName(doc.type)}_${doc.number}.pdf');
    await file.writeAsBytes(pdfBytes);
    await Share.shareXFiles([XFile(file.path)], text: 'Here is your ${_docTypeName(doc.type)} from QuickDocs Rwanda!');
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final id = GoRouterState.of(context).queryParams['id'];
    
    // If id is provided, always fetch the real document from Firebase
    if (id != null) {
      return FutureBuilder<Document?>(
        future: appState.getDocumentById(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final doc = snapshot.data;
          if (doc == null) {
            return _buildDocumentNotFound(context);
          }
          return _buildPreviewScaffold(context, appState, doc);
        },
      );
    }
    
    // Check if document is passed directly via extra parameter
    Document? doc = document;
    final goRouterDoc = GoRouterState.of(context).extra;
    if (doc == null && goRouterDoc is Document) {
      doc = goRouterDoc;
    }
    
    // If no document is found, show error
    if (doc == null) {
      return _buildDocumentNotFound(context);
    }
    
    return _buildPreviewScaffold(context, appState, doc);
  }

  Widget _buildDocumentNotFound(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: const Text('Document Not Found', style: AppTypography.titleMedium),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.document_scanner, size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text('Document not found', style: AppTypography.bodyLarge),
            SizedBox(height: 8),
            Text('The document you are looking for does not exist or has been removed.', 
                 style: AppTypography.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewScaffold(BuildContext context, AppState appState, Document realDoc) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: Text('${_docTypeName(realDoc.type)} Preview', style: AppTypography.titleMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: AppColors.textSecondary),
            tooltip: 'Download PDF',
            onPressed: () async {
              final pdfBytes = await _generatePdf(realDoc, appState);
              await Printing.sharePdf(bytes: pdfBytes, filename: '${_docTypeName(realDoc.type)}_${realDoc.number}.pdf');
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.success),
            tooltip: 'Share on WhatsApp',
            onPressed: () => _sharePdfWhatsApp(context, realDoc, appState),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Stunning From/To section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.business, color: AppColors.primary, size: 22),
                                SizedBox(width: 8),
                                Text('From', style: AppTypography.bodySmall),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(appState.userProfile?.businessName ?? appState.userProfile?.name ?? 'Your Business Name', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                            Text(appState.currentUser?.email ?? 'your@email.com', style: AppTypography.bodySmall),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 48,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        color: AppColors.gray300,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.person, color: AppColors.secondary, size: 22),
                                SizedBox(width: 8),
                                Text('To', style: AppTypography.bodySmall),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(realDoc.clientInfo.name, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                            if (realDoc.clientInfo.email != null)
                              Text(realDoc.clientInfo.email!, style: AppTypography.bodySmall),
                            if (realDoc.clientInfo.phone != null)
                              Text(realDoc.clientInfo.phone!, style: AppTypography.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(realDoc.status),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _getStatusDisplayName(realDoc.status), 
                      style: AppTypography.bodyMedium.copyWith(
                        color: _getStatusTextColor(realDoc.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text('RWF ${realDoc.total.toStringAsFixed(2)}', style: AppTypography.headlineMedium),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                color: AppColors.background,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Document Date', style: AppTypography.bodySmall),
                                Text(_formatDate(realDoc.createdDate), style: AppTypography.bodyMedium),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Due Date', style: AppTypography.bodySmall),
                                Text(realDoc.dueDate != null ? _formatDate(realDoc.dueDate!) : '-', style: AppTypography.bodyMedium),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Document Number', style: AppTypography.bodySmall),
                                Text(realDoc.number, style: AppTypography.bodyMedium),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Status', style: AppTypography.bodySmall),
                                Text(_getStatusDisplayName(realDoc.status), style: AppTypography.bodyMedium),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Items', style: AppTypography.titleMedium),
                      const SizedBox(height: 12),
                      ...realDoc.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: AppTypography.bodyMedium),
                                  Text('${item.quantity} × RWF ${item.price.toStringAsFixed(2)}', style: AppTypography.bodySmall),
                                ],
                              ),
                            ),
                            Text('RWF ${item.total.toStringAsFixed(2)}', style: AppTypography.bodyMedium),
                          ],
                        ),
                      )),
                      const SizedBox(height: 8),
                      const Divider(height: 16, color: AppColors.background),
                      if (realDoc.discount > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal', style: AppTypography.bodyMedium),
                            Text('RWF ${realDoc.subtotal.toStringAsFixed(2)}', style: AppTypography.bodyMedium),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Discount', style: AppTypography.bodyMedium),
                            Text('- RWF ${realDoc.discount.toStringAsFixed(2)}', style: AppTypography.bodyMedium),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('VAT (${(realDoc.vatRate * 100).toStringAsFixed(0)}%)', style: AppTypography.bodyMedium),
                          Text('RWF ${realDoc.vatAmount.toStringAsFixed(2)}', style: AppTypography.bodyMedium),
                        ],
                      ),
                      const Divider(height: 16, color: AppColors.gray300),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: AppTypography.titleMedium),
                          Text('RWF ${realDoc.total.toStringAsFixed(2)}', style: AppTypography.titleMedium),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Download PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: AppTypography.labelLarge,
                  ),
                  onPressed: () => _downloadPdf(context, realDoc, appState),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.email),
                      label: const Text('Email'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: AppTypography.bodyMedium,
                      ),
                      onPressed: () {
                        // TODO: Implement email sharing
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Email sharing coming soon!')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: AppTypography.bodyMedium,
                      ),
                      onPressed: () => _sharePdfWhatsApp(context, realDoc, appState),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.pending:
        return AppColors.orange100;
      case DocumentStatus.paid:
        return AppColors.green100;
      case DocumentStatus.overdue:
        return AppColors.red50;
      case DocumentStatus.cancelled:
        return AppColors.gray200;
      default:
        return AppColors.gray200;
    }
  }

  Color _getStatusTextColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.pending:
        return AppColors.orange600;
      case DocumentStatus.paid:
        return AppColors.green600;
      case DocumentStatus.overdue:
        return AppColors.error;
      case DocumentStatus.cancelled:
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusDisplayName(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.pending:
        return 'Pending';
      case DocumentStatus.paid:
        return 'Paid';
      case DocumentStatus.overdue:
        return 'Overdue';
      case DocumentStatus.cancelled:
        return 'Cancelled';
      default:
        return status.name;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

String _docTypeName(DocumentType type) {
  switch (type) {
    case DocumentType.invoice:
      return 'Invoice';
    case DocumentType.quote:
      return 'Quote';
    case DocumentType.deliveryNote:
      return 'Delivery Note';
    case DocumentType.proforma:
      return 'Proforma';
  }
}
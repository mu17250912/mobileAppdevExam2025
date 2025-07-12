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
  import 'package:flutter/foundation.dart' show kIsWeb;

  class DocumentDetailScreen extends StatelessWidget {
    const DocumentDetailScreen({Key? key}) : super(key: key);

    @override
    Widget build(BuildContext context) {
      final appState = Provider.of<AppState>(context);
      final id = GoRouterState.of(context).queryParams['id'];
      if (id == null) {
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
          body: const Center(child: Text('Document not found', style: AppTypography.bodyLarge)),
        );
      }
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
              body: const Center(child: Text('Document not found', style: AppTypography.bodyLarge)),
            );
          }
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
              title: Text(doc.number, style: AppTypography.titleMedium),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        // Navigate to edit screen (to be implemented)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DocumentEditScreen(document: doc),
                          ),
                        );
                        break;
                      case 'delete':
                        _showDeleteConfirmation(context, doc.id);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: AppColors.textSecondary),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.green100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: DropdownButton<DocumentStatus>(
                            value: doc.status,
                            underline: SizedBox(),
                            onChanged: (newStatus) async {
                              if (newStatus != null && newStatus != doc.status) {
                                await appState.updateDocumentStatus(doc.id, newStatus);
                                // Optionally refresh UI
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Status updated to ${newStatus.toString().split('.').last}')),
                                );
                              }
                            },
                            items: DocumentStatus.values.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status.toString().split('.').last),
                              );
                            }).toList(),
                          ),
                        ),
                        Text('RWF 	${doc.total.toStringAsFixed(2)}', style: AppTypography.headlineMedium),
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
                                      const Text('Invoice Date', style: AppTypography.bodySmall),
                                      Text(_formatDate(doc.createdDate), style: AppTypography.bodyMedium),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Due Date', style: AppTypography.bodySmall),
                                      Text(doc.dueDate != null ? _formatDate(doc.dueDate!) : '-', style: AppTypography.bodyMedium),
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
                                      const Text('Client', style: AppTypography.bodySmall),
                                      Text(doc.clientInfo.name, style: AppTypography.bodyMedium),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Payment Status', style: AppTypography.bodySmall),
                                      Text(doc.status.name, style: AppTypography.bodyMedium),
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
                            ...doc.items.map((item) => Row(
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
                                )),
                            const Divider(height: 16, color: AppColors.background),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('VAT (${(doc.vatRate * 100).toStringAsFixed(0)}%)', style: AppTypography.bodyMedium),
                                Text('RWF ${doc.vatAmount.toStringAsFixed(2)}', style: AppTypography.bodyMedium),
                              ],
                            ),
                            const Divider(height: 16, color: AppColors.gray300),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total', style: AppTypography.titleMedium),
                                Text('RWF ${doc.total.toStringAsFixed(2)}', style: AppTypography.titleMedium),
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
                        onPressed: () async {
                          if (kIsWeb) {
                            await Printing.layoutPdf(
                              onLayout: (format) async => await _generatePdf(doc, appState),
                              name: '${doc.type.name}_${doc.number}.pdf',
                            );
                          } else {
                            await _downloadPdf(context, doc, appState);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.background,
                              foregroundColor: AppColors.textSecondary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              textStyle: AppTypography.bodyMedium,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DocumentEditScreen(document: doc),
                                ),
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
                            onPressed: () async {
                              if (kIsWeb) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Sharing is not supported on web. Please download the PDF instead.')),
                                );
                              } else {
                                await _sharePdfWhatsApp(context, doc, appState);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.red50,
                              foregroundColor: AppColors.error,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              textStyle: AppTypography.bodyMedium,
                            ),
                            onPressed: () => _showDeleteConfirmation(context, doc.id),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    void _showDeleteConfirmation(BuildContext context, String docId) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Document'),
          content: const Text('Are you sure you want to delete this document? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  context.pop();
                } else {
                  context.go('/dashboard');
                }
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final appState = Provider.of<AppState>(context, listen: false);
                appState.deleteDocument(docId);
                if (Navigator.of(context).canPop()) {
                  context.pop();
                } else {
                  context.go('/dashboard');
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Document deleted successfully.')),
                );
                context.go('/document-history');
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }

    String _formatDate(DateTime date) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }

    // PDF generation and sharing helpers
    Future<Uint8List> _generatePdf(Document doc, AppState appState) async {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(doc.type.name.toUpperCase(), style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
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
                        pw.Text('RWF 	{item.total.toStringAsFixed(2)}'),
                      ],
                    )),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('VAT (	0{(doc.vatRate * 100).toStringAsFixed(0)}%)'),
                    pw.Text('RWF 	0{doc.vatAmount.toStringAsFixed(2)}'),
                  ],
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('RWF 	0{doc.total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
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
      final file = File('${dir.path}/${doc.type.name}_${doc.number}.pdf');
      await file.writeAsBytes(pdfBytes);
      await Printing.sharePdf(bytes: pdfBytes, filename: '${doc.type.name}_${doc.number}.pdf');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF downloaded and ready to share!')),
      );
    }

    Future<void> _sharePdfWhatsApp(BuildContext context, Document doc, AppState appState) async {
      final pdfBytes = await _generatePdf(doc, appState);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${doc.type.name}_${doc.number}.pdf');
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Here is your ${doc.type.name} from QuickDocs Rwanda!');
    }
  }

  class DocumentEditScreen extends StatefulWidget {
    final Document document;
    const DocumentEditScreen({Key? key, required this.document}) : super(key: key);

    @override
    State<DocumentEditScreen> createState() => _DocumentEditScreenState();
  }

  class _DocumentEditScreenState extends State<DocumentEditScreen> {
    late TextEditingController _clientNameController;
    late TextEditingController _clientEmailController;
    late TextEditingController _clientPhoneController;
    late TextEditingController _discountController;
    late List<DocumentItem> items;
    bool _loading = false;

    @override
    void initState() {
      super.initState();
      _clientNameController = TextEditingController(text: widget.document.clientInfo.name);
      _clientEmailController = TextEditingController(text: widget.document.clientInfo.email ?? '');
      _clientPhoneController = TextEditingController(text: widget.document.clientInfo.phone ?? '');
      _discountController = TextEditingController(text: widget.document.discount.toString());
      items = List<DocumentItem>.from(widget.document.items);
    }

    @override
    void dispose() {
      _clientNameController.dispose();
      _clientEmailController.dispose();
      _clientPhoneController.dispose();
      _discountController.dispose();
      super.dispose();
    }

    void _save() async {
      setState(() { _loading = true; });
      final appState = Provider.of<AppState>(context, listen: false);
      final updatedDoc = widget.document.copyWith(
        clientInfo: widget.document.clientInfo.copyWith(
          name: _clientNameController.text.trim(),
          email: _clientEmailController.text.trim().isEmpty ? null : _clientEmailController.text.trim(),
          phone: _clientPhoneController.text.trim().isEmpty ? null : _clientPhoneController.text.trim(),
        ),
        items: items,
        discount: double.tryParse(_discountController.text) ?? 0.0,
      );
      await appState.updateDocument(updatedDoc);
      setState(() { _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document updated!')),
      );
      Navigator.pop(context);
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Document')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _clientNameController,
                      decoration: const InputDecoration(labelText: 'Client Name'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _clientEmailController,
                      decoration: const InputDecoration(labelText: 'Client Email'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _clientPhoneController,
                      decoration: const InputDecoration(labelText: 'Client Phone'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _discountController,
                      decoration: const InputDecoration(labelText: 'Discount'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _save,
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
      );
    }
  }

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/ai_assistant_service.dart';
import '../services/report_service.dart';
import 'package:printing/printing.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({Key? key}) : super(key: key);

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;
  final AiAssistantService _aiService = AiAssistantService();
  final ReportService _reportService = ReportService();

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isSending = true;
    });
    _controller.clear();
    
    try {
      final lang = Localizations.localeOf(context).languageCode;
      final aiReply = await _aiService.getIntelligentResponse(text, lang);
      setState(() {
        _messages.add(_ChatMessage(text: aiReply, isUser: false));
        _isSending = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(text: 'Sorry, I encountered an error. Please try again.', isUser: false));
        _isSending = false;
      });
    }
  }

  // Generate comprehensive business report
  Future<void> _generateBusinessReport() async {
    try {
      final lang = Localizations.localeOf(context).languageCode;
      final pdfBytes = await _reportService.generateBusinessReport(language: lang);
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: $e')),
      );
    }
  }

  // Generate minimization strategy report
  Future<void> _generateMinimizationStrategy() async {
    try {
      final strategy = await _aiService.generateDetailedMinimizationStrategy();
      final lang = Localizations.localeOf(context).languageCode;
      
      // Create PDF for minimization strategy
      final pdf = pw.Document();
      final font = pw.Font.helvetica();
      final boldFont = pw.Font.helveticaBold();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  lang == 'fr' ? 'Stratégie de Minimisation des Coûts' : 'Cost Minimization Strategy',
                  style: pw.TextStyle(font: boldFont, fontSize: 24),
                ),
                pw.SizedBox(height: 20),
                
                // Summary
                pw.Text(
                  lang == 'fr' ? 'Résumé' : 'Summary',
                  style: pw.TextStyle(font: boldFont, fontSize: 18),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  '${lang == 'fr' ? 'Économies potentielles totales' : 'Total potential savings'}: ${strategy['summary']['totalPotentialSavings']}',
                  style: pw.TextStyle(font: font, fontSize: 14),
                ),
                pw.Text(
                  '${lang == 'fr' ? 'Délai de mise en œuvre' : 'Implementation timeframe'}: ${strategy['summary']['implementationTimeframe']}',
                  style: pw.TextStyle(font: font, fontSize: 14),
                ),
                pw.SizedBox(height: 20),

                // Strategies
                ...strategy['strategies'].entries.map<pw.Widget>((entry) {
                  final strategyData = entry.value as Map<String, dynamic>;
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        strategyData['title'],
                        style: pw.TextStyle(font: boldFont, fontSize: 16),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        strategyData['description'],
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        '${lang == 'fr' ? 'Actions' : 'Actions'}:',
                        style: pw.TextStyle(font: boldFont, fontSize: 12),
                      ),
                      ...(strategyData['actions'] as List).map<pw.Widget>((action) => 
                        pw.Padding(
                          padding: pw.EdgeInsets.only(left: 10),
                          child: pw.Text('• $action', style: pw.TextStyle(font: font, fontSize: 10)),
                        ),
                      ).toList(),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        '${lang == 'fr' ? 'Économies potentielles' : 'Potential savings'}: ${strategyData['potentialSavings']}',
                        style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.green),
                      ),
                      pw.Text(
                        '${lang == 'fr' ? 'Temps de mise en œuvre' : 'Implementation time'}: ${strategyData['implementationTime']}',
                        style: pw.TextStyle(font: font, fontSize: 10),
                      ),
                      pw.SizedBox(height: 20),
                    ],
                  );
                }).toList(),
              ],
            );
          },
        ),
      );

      final pdfBytes = pdf.save();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating strategy: $e')),
      );
    }
  }

  // --- PRINT & SAVE FUNCTIONALITY ---
  Future<void> _printChat() async {
    final lang = Localizations.localeOf(context).languageCode;
    final chatText = _messages.map((m) => (m.isUser ? (lang == 'fr' ? 'Vous: ' : 'You: ') : (lang == 'fr' ? 'Assistant: ' : 'Assistant: ')) + m.text).join('\n\n');
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) => pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Text(chatText, style: pw.TextStyle(fontSize: 16)),
            ),
          ),
        );
        return pdf.save();
      },
    );
  }

  Future<void> _saveChat() async {
    final lang = Localizations.localeOf(context).languageCode;
    final chatText = _messages.map((m) => (m.isUser ? (lang == 'fr' ? 'Vous: ' : 'You: ') : (lang == 'fr' ? 'Assistant: ' : 'Assistant: ')) + m.text).join('\n\n');
    try {
      if (await Permission.storage.request().isGranted) {
        final directory = await getExternalStorageDirectory();
        final path = directory?.path ?? (await getApplicationDocumentsDirectory()).path;
        final file = File('$path/ai_chat_${DateTime.now().millisecondsSinceEpoch}.txt');
        await file.writeAsString(chatText);
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(lang == 'fr' ? 'Succès' : 'Success'),
            content: Text(lang == 'fr'
                ? 'La conversation a été enregistrée dans vos fichiers.'
                : 'Chat has been saved to your files.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(lang == 'fr' ? 'OK' : 'OK'),
              ),
            ],
          ),
        );
      } else {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(lang == 'fr' ? 'Permission refusée' : 'Permission Denied'),
            content: Text(lang == 'fr'
                ? "L'application n'a pas la permission d'accéder au stockage."
                : 'The app does not have permission to access storage.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(lang == 'fr' ? 'OK' : 'OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(lang == 'fr' ? 'Erreur' : 'Error'),
          content: Text((lang == 'fr'
              ? 'Erreur lors de la sauvegarde de la conversation: '
              : 'Error saving chat: ') + e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang == 'fr' ? 'OK' : 'OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = const Color(0xFFFFD600);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.aiAssistant),
        backgroundColor: mainColor,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'print_chat':
                  _printChat();
                  break;
                case 'save_chat':
                  _saveChat();
                  break;
                case 'business_report':
                  _generateBusinessReport();
                  break;
                case 'minimization_strategy':
                  _generateMinimizationStrategy();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'print_chat',
                child: Row(
                  children: [
                    const Icon(Icons.print),
                    const SizedBox(width: 8),
                    Text(Localizations.localeOf(context).languageCode == 'fr'
                        ? 'Imprimer la conversation'
                        : 'Print chat'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'save_chat',
                child: Row(
                  children: [
                    const Icon(Icons.save_alt),
                    const SizedBox(width: 8),
                    Text(Localizations.localeOf(context).languageCode == 'fr'
                        ? 'Enregistrer la conversation'
                        : 'Save chat'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'business_report',
                child: Row(
                  children: [
                    const Icon(Icons.assessment),
                    const SizedBox(width: 8),
                    Text(Localizations.localeOf(context).languageCode == 'fr'
                        ? 'Rapport d\'entreprise'
                        : 'Business Report'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'minimization_strategy',
                child: Row(
                  children: [
                    const Icon(Icons.trending_down),
                    const SizedBox(width: 8),
                    Text(Localizations.localeOf(context).languageCode == 'fr'
                        ? 'Stratégie de minimisation'
                        : 'Minimization Strategy'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: msg.isUser ? mainColor : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: msg.isUser ? Colors.black : Colors.grey.shade900,
                        fontWeight: msg.isUser ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isSending)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 16),
                  const CircularProgressIndicator(strokeWidth: 2),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context)!.aiAssistant + '...'),
                ],
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.aiAssistant +
                            (Localizations.localeOf(context).languageCode == 'fr'
                                ? ' : Posez-moi une question...'
                                : ': Ask me anything...'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.black),
                    onPressed: _isSending
                        ? null
                        : () => _sendMessage(_controller.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
} 
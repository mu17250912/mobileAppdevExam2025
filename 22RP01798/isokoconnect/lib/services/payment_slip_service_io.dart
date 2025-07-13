import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/order_model.dart';

class PaymentSlipService {
  static Future<String> generatePaymentSlip(OrderModel order) async {
    return _generatePaymentSlipInternal(order).timeout(
      const Duration(seconds: 5), // 5 seconds timeout as requested
      onTimeout: () {
        throw Exception('PDF generation timed out. Please try again.');
      },
    );
  }

  // Simple test method to check if PDF generation works
  static Future<String> generateSimpleTestPDF() async {
    try {
      print('Generating simple test PDF...');
      
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Test PDF - IsokoConnect',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          },
        ),
      );

      // Try to save to Downloads folder first
      String filePath = await _saveToDownloads(pdf, 'test_pdf_${DateTime.now().millisecondsSinceEpoch}.pdf');
      
      print('Test PDF generated successfully: $filePath');
      return filePath;
    } catch (e) {
      print('Error in test PDF generation: $e');
      rethrow;
    }
  }

  static Future<String> _generatePaymentSlipInternal(OrderModel order) async {
    try {
      print('Starting PDF generation for order: ${order.id}');
      
      // Use built-in font to avoid font loading issues
      final ttf = pw.Font.helvetica();
      print('Using built-in font');

      // Create PDF document with optimized settings
      final pdf = pw.Document();

      // Add page to PDF with simplified content for faster generation
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header - Simplified for speed
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'ISOKO CONNECT',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Payment Receipt',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 14,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                // Payment Details - Simplified
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Payment Details',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      _buildDetailRow('Order ID', order.id, ttf),
                      _buildDetailRow('Payment Date', _formatDate(order.updatedAt ?? order.createdAt), ttf),
                      _buildDetailRow('Payment Status', 'PAID', ttf),
                      _buildDetailRow('Payment Method', 'MTN MoMo', ttf),
                      _buildDetailRow('MoMo Account', order.buyerMomoAccount ?? 'N/A', ttf),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                // Order Details - Simplified
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Order Details',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      _buildDetailRow('Product Name', order.productName, ttf),
                      _buildDetailRow('Quantity', '${order.quantity} kg', ttf),
                      _buildDetailRow('Price per kg', '${order.pricePerKg.toStringAsFixed(0)} RWF', ttf),
                      _buildDetailRow('Total Amount', '${order.totalAmount.toStringAsFixed(0)} RWF', ttf),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                // Buyer Details - Simplified
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Buyer Information',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      _buildDetailRow('Name', order.buyerName, ttf),
                      _buildDetailRow('Phone', order.buyerPhone, ttf),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                // Seller Details - Simplified
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Seller Information',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      _buildDetailRow('Name', order.sellerName, ttf),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                // Footer - Simplified
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey.shade(0.1),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Thank you for using IsokoConnect!',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'This receipt serves as proof of payment.',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 10,
                          color: PdfColors.grey.shade(0.6),
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Try to save to Downloads folder
      String filePath = await _saveToDownloads(pdf, 'payment_slip_${order.id}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      
      print('PDF generation completed successfully: $filePath');
      return filePath;
    } catch (e) {
      print('Error in PDF generation: $e');
      rethrow;
    }
  }

  // Helper method to save PDF to Downloads folder
  static Future<String> _saveToDownloads(pw.Document pdf, String filename) async {
    try {
      // Request storage permissions
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          print('Storage permission not granted, trying external storage');
        }
      }

      // Request manage external storage permission for Android 11+
      var manageStatus = await Permission.manageExternalStorage.status;
      if (!manageStatus.isGranted) {
        manageStatus = await Permission.manageExternalStorage.request();
        if (!manageStatus.isGranted) {
          print('Manage external storage permission not granted');
        }
      }

      // Try multiple download paths
      List<String> downloadPaths = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Downloads',
        '/sdcard/Download',
        '/sdcard/Downloads',
      ];

      for (String path in downloadPaths) {
        try {
          final dir = Directory(path);
          if (await dir.exists()) {
            final file = File('${dir.path}/$filename');
            print('Attempting to save to: ${file.path}');
            
            final bytes = await pdf.save().timeout(
              const Duration(seconds: 3),
              onTimeout: () => throw Exception('PDF save timed out'),
            );
            
            await file.writeAsBytes(bytes).timeout(
              const Duration(seconds: 2),
              onTimeout: () => throw Exception('File write timed out'),
            );
            
            // Verify file was created
            if (await file.exists()) {
              print('Successfully saved to Downloads: ${file.path}');
              return file.path;
            }
          }
        } catch (e) {
          print('Failed to save to $path: $e');
          continue;
        }
      }

      // Fallback to app documents directory
      print('Falling back to app directory');
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      
      final bytes = await pdf.save().timeout(
        const Duration(seconds: 3),
        onTimeout: () => throw Exception('PDF save timed out'),
      );
      
      await file.writeAsBytes(bytes).timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw Exception('File write timed out'),
      );
      
      print('Saved to app directory: ${file.path}');
      return file.path;
    } catch (e) {
      print('Error saving PDF: $e');
      rethrow;
    }
  }

  static pw.Widget _buildDetailRow(String label, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: font,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey.shade(0.7),
                fontSize: 10,
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: font,
                fontWeight: pw.FontWeight.normal,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Method to verify if a file exists and get its size
  static Future<Map<String, dynamic>> verifyFileExists(String filePath) async {
    try {
      final file = File(filePath);
      final exists = await file.exists();
      if (exists) {
        final size = await file.length();
        return {
          'exists': true,
          'path': filePath,
          'size': size,
          'sizeInKB': (size / 1024).toStringAsFixed(2),
        };
      } else {
        return {
          'exists': false,
          'path': filePath,
          'error': 'File not found',
        };
      }
    } catch (e) {
      return {
        'exists': false,
        'path': filePath,
        'error': e.toString(),
      };
    }
  }
} 
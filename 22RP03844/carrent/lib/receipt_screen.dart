import 'package:flutter/material.dart';
import 'success_screen.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';

class ReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> receipt;
  const ReceiptScreen({Key? key, required this.receipt}) : super(key: key);

  // Helper method to format dates
  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';
    DateTime? date;
    if (dateValue is String) {
      try {
        date = DateTime.parse(dateValue);
      } catch (_) {
        return 'Invalid Date';
      }
    } else if (dateValue is DateTime) {
      date = dateValue;
    } else if (dateValue is Timestamp) {
      date = dateValue.toDate();
    } else {
      return 'Invalid Date';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Helper method to get car name
  String _getCarName() {
    final brand = receipt['carBrand'] ?? receipt['brand'] ?? '';
    final model = receipt['carModel'] ?? receipt['model'] ?? '';
    if (brand.isNotEmpty && model.isNotEmpty) {
      return '$brand $model';
    } else if (brand.isNotEmpty) {
      return brand;
    } else if (model.isNotEmpty) {
      return model;
    }
    return 'N/A';
  }

  // Helper method to get pickup location
  String _getPickupLocation() {
    return receipt['pickupLocation'] ?? receipt['pickup'] ?? 'N/A';
  }

  // Helper method to get dropoff location
  String _getDropoffLocation() {
    return receipt['dropoffLocation'] ?? receipt['dropoff'] ?? 'N/A';
  }

  // Helper method to get payment method
  String _getPaymentMethod() {
    return receipt['paymentMethod'] ?? 'N/A';
  }

  // Helper method to get total amount
  String _getTotalAmount() {
    final total = receipt['totalPrice'] ?? receipt['total'] ?? 0;
    return '$total RWF';
  }

  // Helper method to get rental dates string
  String _getRentalDates() {
    return '${_formatDate(receipt['startDate'])} to ${_formatDate(receipt['endDate'])}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Receipt'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.receipt_long, color: Colors.white, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'Payment Receipt',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Receipt Details
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReceiptRow('Car:', _getCarName()),
                      const SizedBox(height: 12),
                      _buildReceiptRow('Rental Dates:', _getRentalDates()),
                      const SizedBox(height: 12),
                      _buildReceiptRow('Pickup:', _getPickupLocation()),
                      const SizedBox(height: 12),
                      _buildReceiptRow('Drop-off:', _getDropoffLocation()),
                      const SizedBox(height: 12),
                      _buildReceiptRow('Payment Method:', _getPaymentMethod()),
                      if (receipt['paymentNumber'] != null && receipt['paymentNumber'].toString().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildReceiptRow('Payment Number:', receipt['paymentNumber'].toString()),
                      ],
                      const Divider(height: 32),
                      _buildReceiptRow('Total Paid:', _getTotalAmount(), isTotal: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Action Buttons
              Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final pdf = pw.Document();
                          final logoBytes = await rootBundle.load('assets/logo.png');
                          final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
                          pdf.addPage(
                            pw.Page(
                              build: (pw.Context context) => pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Center(
                                    child: pw.Image(logoImage, width: 100, height: 100),
                                  ),
                                  pw.SizedBox(height: 16),
                                  pw.Text('Payment Receipt', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                                  pw.SizedBox(height: 24),
                                  pw.Text('Car: ${_getCarName()}'),
                                  pw.Text('Rental Dates: ${_getRentalDates()}'),
                                  pw.Text('Pickup: ${_getPickupLocation()}'),
                                  pw.Text('Drop-off: ${_getDropoffLocation()}'),
                                  pw.Text('Payment Method: ${_getPaymentMethod()}'),
                                  if (receipt['paymentNumber'] != null && receipt['paymentNumber'].toString().isNotEmpty)
                                    pw.Text('Payment Number: ${receipt['paymentNumber']}'),
                                  pw.Text('Total Paid: ${_getTotalAmount()}'),
                                ],
                              ),
                            ),
                          );
                          await Printing.layoutPdf(onLayout: (format) async => pdf.save());
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('View/Download PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667eea),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const SuccessScreen(receipt: {})),
                          );
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Done'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isTotal = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? const Color(0xFF667eea) : Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
              color: isTotal ? const Color(0xFF667eea) : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
} 
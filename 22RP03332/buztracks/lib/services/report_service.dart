import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'dart:math';
import 'dart:typed_data';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Business Analytics
  Future<Map<String, dynamic>> getBusinessAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final start = startDate ?? DateTime.now().subtract(Duration(days: 30));
    final end = endDate ?? DateTime.now();

    // Get sales data
    final salesQuery = await _firestore
        .collection('Sales')
        .where('userId', isEqualTo: currentUserId)
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .where('createdAt', isLessThanOrEqualTo: end)
        .get();

    final sales = salesQuery.docs.map((doc) => doc.data()).toList();

    // Get products data
    final productsQuery = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('products')
        .get();

    final products = productsQuery.docs.map((doc) => doc.data()).toList();

    // Get customers data
    final customersQuery = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('customers')
        .get();

    final customers = customersQuery.docs.map((doc) => doc.data()).toList();

    // Calculate analytics
    final totalSales = sales.fold<double>(0, (sum, sale) => sum + (sale['totalAmount'] ?? 0));
    final totalTransactions = sales.length;
    final averageTransactionValue = totalTransactions > 0 ? totalSales / totalTransactions : 0;
    
    // Top selling products
    final productSales = <String, int>{};
    for (final sale in sales) {
      final productName = sale['productName'] ?? 'Unknown';
      productSales[productName] = (productSales[productName] ?? 0) + ((sale['quantity'] ?? 0) as int);
    }
    final topProducts = productSales.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

    // Low stock products
    final lowStockProducts = products.where((p) => (p['stock'] ?? 0) <= (p['minStock'] ?? 10)).toList();

    // Customer analytics
    final customerSales = <String, double>{};
    for (final sale in sales) {
      final customerName = sale['customerName'] ?? 'Walk-in';
      customerSales[customerName] = (customerSales[customerName] ?? 0) + (sale['totalAmount'] ?? 0);
    }
    final topCustomers = customerSales.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

    // Payment method distribution
    final paymentMethods = <String, int>{};
    for (final sale in sales) {
      final method = sale['paymentMethod'] ?? 'Unknown';
      paymentMethods[method] = (paymentMethods[method] ?? 0) + 1;
    }

    // Daily sales trend
    final dailySales = <String, double>{};
    for (final sale in sales) {
      final date = (sale['createdAt'] as Timestamp).toDate();
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      dailySales[dateKey] = (dailySales[dateKey] ?? 0) + (sale['totalAmount'] ?? 0);
    }

    return {
      'totalSales': totalSales,
      'totalTransactions': totalTransactions,
      'averageTransactionValue': averageTransactionValue,
      'topProducts': topProducts.take(5).toList(),
      'lowStockProducts': lowStockProducts,
      'topCustomers': topCustomers.take(5).toList(),
      'paymentMethods': paymentMethods,
      'dailySales': dailySales,
      'period': {
        'start': start,
        'end': end,
      },
    };
  }

  // Generate PDF Report
  Future<Uint8List> generateBusinessReport({
    DateTime? startDate,
    DateTime? endDate,
    String language = 'en',
  }) async {
    final analytics = await getBusinessAnalytics(startDate: startDate, endDate: endDate);
    
    final pdf = pw.Document();
    final font = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();

    // Header
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    language == 'fr' ? 'Rapport d\'Entreprise' : 'Business Report',
                    style: pw.TextStyle(font: boldFont, fontSize: 24),
                  ),
                  pw.Text(
                    DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              
              // Period
              pw.Text(
                language == 'fr' 
                    ? 'Période: ${DateFormat('dd/MM/yyyy').format(analytics['period']['start'])} - ${DateFormat('dd/MM/yyyy').format(analytics['period']['end'])}'
                    : 'Period: ${DateFormat('dd/MM/yyyy').format(analytics['period']['start'])} - ${DateFormat('dd/MM/yyyy').format(analytics['period']['end'])}',
                style: pw.TextStyle(font: font, fontSize: 14),
              ),
              pw.SizedBox(height: 20),

              // Key Metrics
              pw.Text(
                language == 'fr' ? 'Métriques Clés' : 'Key Metrics',
                style: pw.TextStyle(font: boldFont, fontSize: 18),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey),
                        borderRadius: pw.BorderRadius.circular(5),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            language == 'fr' ? 'Ventes Totales' : 'Total Sales',
                            style: pw.TextStyle(font: font, fontSize: 12),
                          ),
                          pw.Text(
                            '${NumberFormat('#,##0').format(analytics['totalSales'])} RWF',
                            style: pw.TextStyle(font: boldFont, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Container(
                      padding: pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey),
                        borderRadius: pw.BorderRadius.circular(5),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            language == 'fr' ? 'Transactions' : 'Transactions',
                            style: pw.TextStyle(font: font, fontSize: 12),
                          ),
                          pw.Text(
                            analytics['totalTransactions'].toString(),
                            style: pw.TextStyle(font: boldFont, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Container(
                      padding: pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey),
                        borderRadius: pw.BorderRadius.circular(5),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            language == 'fr' ? 'Moyenne' : 'Average',
                            style: pw.TextStyle(font: font, fontSize: 12),
                          ),
                          pw.Text(
                            '${NumberFormat('#,##0').format(analytics['averageTransactionValue'])} RWF',
                            style: pw.TextStyle(font: boldFont, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Top Products
              pw.Text(
                language == 'fr' ? 'Produits les Plus Vendus' : 'Top Selling Products',
                style: pw.TextStyle(font: boldFont, fontSize: 18),
              ),
              pw.SizedBox(height: 10),
              ...analytics['topProducts'].map<pw.Widget>((product) => 
                pw.Padding(
                  padding: pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(product.key, style: pw.TextStyle(font: font, fontSize: 12)),
                      pw.Text('${product.value} units', style: pw.TextStyle(font: font, fontSize: 12)),
                    ],
                  ),
                ),
              ).toList(),
              pw.SizedBox(height: 20),

              // Low Stock Alert
              if (analytics['lowStockProducts'].isNotEmpty) ...[
                pw.Text(
                  language == 'fr' ? 'Alerte Stock Faible' : 'Low Stock Alert',
                  style: pw.TextStyle(font: boldFont, fontSize: 18, color: PdfColors.red),
                ),
                pw.SizedBox(height: 10),
                ...analytics['lowStockProducts'].map<pw.Widget>((product) => 
                  pw.Padding(
                    padding: pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Text(
                      '${product['name']} - Stock: ${product['stock']}',
                      style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.red),
                    ),
                  ),
                ).toList(),
                pw.SizedBox(height: 20),
              ],

              // Top Customers
              pw.Text(
                language == 'fr' ? 'Meilleurs Clients' : 'Top Customers',
                style: pw.TextStyle(font: boldFont, fontSize: 18),
              ),
              pw.SizedBox(height: 10),
              ...analytics['topCustomers'].map<pw.Widget>((customer) => 
                pw.Padding(
                  padding: pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(customer.key, style: pw.TextStyle(font: font, fontSize: 12)),
                      pw.Text('${NumberFormat('#,##0').format(customer.value)} RWF', style: pw.TextStyle(font: font, fontSize: 12)),
                    ],
                  ),
                ),
              ).toList(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Generate Minimization Strategy Report
  Future<Map<String, dynamic>> generateMinimizationStrategy() async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final analytics = await getBusinessAnalytics();
    
    // Analyze cost optimization opportunities
    final lowStockProducts = analytics['lowStockProducts'] as List;
    final topProducts = analytics['topProducts'] as List;
    final paymentMethods = analytics['paymentMethods'] as Map<String, int>;
    
    final recommendations = <String, dynamic>{};
    
    // Inventory optimization
    if (lowStockProducts.isNotEmpty) {
      recommendations['inventory'] = {
        'type': 'warning',
        'title': 'Low Stock Alert',
        'description': 'Some products are running low on stock. Consider restocking to avoid lost sales.',
        'products': lowStockProducts.map((p) => p['name']).toList(),
        'action': 'Restock these products to maintain sales momentum.',
      };
    }

    // Top performing products analysis
    if (topProducts.isNotEmpty) {
      final topProduct = topProducts.first;
      recommendations['topProduct'] = {
        'type': 'opportunity',
        'title': 'Best Selling Product',
        'description': '${topProduct.key} is your best seller with ${topProduct.value} units sold.',
        'action': 'Consider increasing stock of this product and promoting it further.',
      };
    }

    // Payment method optimization
    final totalTransactions = analytics['totalTransactions'];
    final cashTransactions = paymentMethods['Cash'] ?? 0;
    final mobileMoneyTransactions = paymentMethods['Mobile Money'] ?? 0;
    
    if (cashTransactions > mobileMoneyTransactions) {
      recommendations['payment'] = {
        'type': 'suggestion',
        'title': 'Payment Method Optimization',
        'description': 'Cash transactions are higher than mobile money. Consider promoting digital payments.',
        'action': 'Offer discounts for mobile money payments to reduce cash handling costs.',
      };
    }

    // Cost reduction opportunities
    final averageTransaction = analytics['averageTransactionValue'];
    if (averageTransaction < 5000) {
      recommendations['pricing'] = {
        'type': 'opportunity',
        'title': 'Average Transaction Value',
        'description': 'Average transaction value is ${NumberFormat('#,##0').format(averageTransaction)} RWF.',
        'action': 'Consider bundling products or offering premium services to increase transaction value.',
      };
    }

    return {
      'recommendations': recommendations,
      'analytics': analytics,
    };
  }

  // Print Report
  Future<Uint8List> printReport({
    DateTime? startDate,
    DateTime? endDate,
    String language = 'en',
  }) async {
    final pdfBytes = await generateBusinessReport(
      startDate: startDate,
      endDate: endDate,
      language: language,
    );
    return pdfBytes;
  }
} 
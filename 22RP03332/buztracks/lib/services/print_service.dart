import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PrintService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Print Sales Receipt
  Future<void> printSalesReceipt(Map<String, dynamic> saleData) async {
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
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'SALES RECEIPT',
                    style: pw.TextStyle(font: boldFont, fontSize: 24),
                  ),
                  pw.Text(
                    DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Sale Details
              pw.Text(
                'Sale Details',
                style: pw.TextStyle(font: boldFont, fontSize: 18),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Product:', style: pw.TextStyle(font: font, fontSize: 12)),
                  pw.Text(saleData['productName'] ?? '', style: pw.TextStyle(font: font, fontSize: 12)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Quantity:', style: pw.TextStyle(font: font, fontSize: 12)),
                  pw.Text(saleData['quantity'].toString(), style: pw.TextStyle(font: font, fontSize: 12)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Unit Price:', style: pw.TextStyle(font: font, fontSize: 12)),
                  pw.Text('${NumberFormat('#,##0').format(saleData['unitPrice'])} RWF', style: pw.TextStyle(font: font, fontSize: 12)),
                ],
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total:', style: pw.TextStyle(font: boldFont, fontSize: 14)),
                  pw.Text('${NumberFormat('#,##0').format(saleData['totalAmount'])} RWF', style: pw.TextStyle(font: boldFont, fontSize: 14)),
                ],
              ),
              pw.SizedBox(height: 20),

              // Payment Information
              pw.Text(
                'Payment Information',
                style: pw.TextStyle(font: boldFont, fontSize: 18),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Payment Method:', style: pw.TextStyle(font: font, fontSize: 12)),
                  pw.Text(saleData['paymentMethod'] ?? '', style: pw.TextStyle(font: font, fontSize: 12)),
                ],
              ),
              if (saleData['customerName'] != null && saleData['customerName'] != 'Walk-in')
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Customer:', style: pw.TextStyle(font: font, fontSize: 12)),
                    pw.Text(saleData['customerName'], style: pw.TextStyle(font: font, fontSize: 12)),
                  ],
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

  // Print Inventory Report
  Future<void> printInventoryReport(List<Map<String, dynamic>> products, String language) async {
    final pdf = pw.Document();
    final font = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();

    final lowStockProducts = products.where((p) => (p['stock'] ?? 0) <= (p['minStock'] ?? 10)).toList();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Text(
                language == 'fr' ? 'Rapport d\'Inventaire' : 'Inventory Report',
                style: pw.TextStyle(font: boldFont, fontSize: 24),
              ),
              pw.Text(
                DateFormat('yyyy-MM-dd').format(DateTime.now()),
                style: pw.TextStyle(font: font, fontSize: 12),
              ),
              pw.SizedBox(height: 20),

              // Summary
              pw.Text(
                language == 'fr' ? 'Résumé' : 'Summary',
                style: pw.TextStyle(font: boldFont, fontSize: 18),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                '${language == 'fr' ? 'Total des produits' : 'Total products'}: ${products.length}',
                style: pw.TextStyle(font: font, fontSize: 14),
              ),
              pw.Text(
                '${language == 'fr' ? 'Valeur totale de l\'inventaire' : 'Total inventory value'}: ${NumberFormat('#,##0').format(_calculateTotalInventoryValue(products))} RWF',
                style: pw.TextStyle(font: font, fontSize: 14),
              ),
              pw.SizedBox(height: 20),

              // Products Table
              pw.Text(
                language == 'fr' ? 'Produits' : 'Products',
                style: pw.TextStyle(font: boldFont, fontSize: 18),
              ),
              pw.SizedBox(height: 10),
              
              // Table Header
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      language == 'fr' ? 'Nom' : 'Name',
                      style: pw.TextStyle(font: boldFont, fontSize: 12),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      language == 'fr' ? 'Prix' : 'Price',
                      style: pw.TextStyle(font: boldFont, fontSize: 12),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      language == 'fr' ? 'Stock' : 'Stock',
                      style: pw.TextStyle(font: boldFont, fontSize: 12),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      language == 'fr' ? 'Valeur' : 'Value',
                      style: pw.TextStyle(font: boldFont, fontSize: 12),
                    ),
                  ),
                ],
              ),
              pw.Divider(),

              // Products
              ...products.map<pw.Widget>((product) {
                final stock = product['stock'] ?? 0;
                final price = product['price'] ?? 0;
                final value = stock * price;
                
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          product['name'] ?? '',
                          style: pw.TextStyle(font: font, fontSize: 10),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          '${NumberFormat('#,##0').format(price)}',
                          style: pw.TextStyle(font: font, fontSize: 10),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          stock.toString(),
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                            color: stock <= (product['minStock'] ?? 10) ? PdfColors.red : PdfColors.black,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          '${NumberFormat('#,##0').format(value)}',
                          style: pw.TextStyle(font: font, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              pw.SizedBox(height: 20),

              // Low Stock Alert
              if (lowStockProducts.isNotEmpty) ...[
                pw.Text(
                  language == 'fr' ? 'Alerte Stock Faible' : 'Low Stock Alert',
                  style: pw.TextStyle(font: boldFont, fontSize: 16, color: PdfColors.red),
                ),
                pw.SizedBox(height: 10),
                ...lowStockProducts.map<pw.Widget>((product) => 
                  pw.Text(
                    '${product['name']} - Stock: ${product['stock']}',
                    style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.red),
                  ),
                ).toList(),
              ],
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // Print Customer Report
  Future<void> printCustomerReport(List<Map<String, dynamic>> customers, String language) async {
    final pdf = pw.Document();
    final font = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();

    final customersWithCredit = customers.where((c) => (c['credit'] ?? 0) > 0).toList();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Text(
                language == 'fr' ? 'Rapport Clients' : 'Customer Report',
                style: pw.TextStyle(font: boldFont, fontSize: 24),
              ),
              pw.Text(
                DateFormat('yyyy-MM-dd').format(DateTime.now()),
                style: pw.TextStyle(font: font, fontSize: 12),
              ),
              pw.SizedBox(height: 20),

              // Summary
              pw.Text(
                language == 'fr' ? 'Résumé' : 'Summary',
                style: pw.TextStyle(font: boldFont, fontSize: 18),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                '${language == 'fr' ? 'Total des clients' : 'Total customers'}: ${customers.length}',
                style: pw.TextStyle(font: font, fontSize: 14),
              ),
              pw.Text(
                '${language == 'fr' ? 'Crédit total' : 'Total credit'}: ${NumberFormat('#,##0').format(_calculateTotalCredit(customers))} RWF',
                style: pw.TextStyle(font: font, fontSize: 14),
              ),
              pw.SizedBox(height: 20),

              // Customers Table
              pw.Text(
                language == 'fr' ? 'Clients' : 'Customers',
                style: pw.TextStyle(font: boldFont, fontSize: 18),
              ),
              pw.SizedBox(height: 10),
              
              // Table Header
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      language == 'fr' ? 'Nom' : 'Name',
                      style: pw.TextStyle(font: boldFont, fontSize: 12),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      language == 'fr' ? 'Téléphone' : 'Phone',
                      style: pw.TextStyle(font: boldFont, fontSize: 12),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      language == 'fr' ? 'Crédit' : 'Credit',
                      style: pw.TextStyle(font: boldFont, fontSize: 12),
                    ),
                  ),
                ],
              ),
              pw.Divider(),

              // Customers
              ...customers.map<pw.Widget>((customer) {
                final credit = customer['credit'] ?? 0;
                
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          customer['name'] ?? '',
                          style: pw.TextStyle(font: font, fontSize: 10),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          customer['phone'] ?? '',
                          style: pw.TextStyle(font: font, fontSize: 10),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          '${NumberFormat('#,##0').format(credit)}',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                            color: credit > 0 ? PdfColors.red : PdfColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              pw.SizedBox(height: 20),

              // Credit Alert
              if (customersWithCredit.isNotEmpty) ...[
                pw.Text(
                  language == 'fr' ? 'Clients avec Crédit' : 'Customers with Credit',
                  style: pw.TextStyle(font: boldFont, fontSize: 16, color: PdfColors.red),
                ),
                pw.SizedBox(height: 10),
                ...customersWithCredit.map<pw.Widget>((customer) => 
                  pw.Text(
                    '${customer['name']} - Crédit: ${NumberFormat('#,##0').format(customer['credit'])} RWF',
                    style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.red),
                  ),
                ).toList(),
              ],
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // Helper methods
  double _calculateTotalInventoryValue(List<Map<String, dynamic>> products) {
    return products.fold<double>(0, (sum, product) {
      final stock = product['stock'] ?? 0;
      final price = product['price'] ?? 0;
      return sum + (stock * price);
    });
  }

  double _calculateTotalCredit(List<Map<String, dynamic>> customers) {
    return customers.fold<double>(0, (sum, customer) {
      return sum + (customer['credit'] ?? 0);
    });
  }

  // Print Daily Summary
  Future<void> printDailySummary(String language) async {
    if (currentUserId == null) return;

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Get today's sales
      final salesQuery = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('sales')
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
          .where('createdAt', isLessThan: endOfDay)
          .get();

      final sales = salesQuery.docs.map((doc) => doc.data()).toList();

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
                // Header
                pw.Text(
                  language == 'fr' ? 'Résumé Quotidien' : 'Daily Summary',
                  style: pw.TextStyle(font: boldFont, fontSize: 24),
                ),
                pw.Text(
                  DateFormat('yyyy-MM-dd').format(today),
                  style: pw.TextStyle(font: font, fontSize: 12),
                ),
                pw.SizedBox(height: 20),

                // Summary
                pw.Text(
                  language == 'fr' ? 'Résumé' : 'Summary',
                  style: pw.TextStyle(font: boldFont, fontSize: 18),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  '${language == 'fr' ? 'Ventes totales' : 'Total sales'}: ${NumberFormat('#,##0').format(_calculateTotalSales(sales))} RWF',
                  style: pw.TextStyle(font: font, fontSize: 14),
                ),
                pw.Text(
                  '${language == 'fr' ? 'Nombre de transactions' : 'Number of transactions'}: ${sales.length}',
                  style: pw.TextStyle(font: font, fontSize: 14),
                ),
                pw.Text(
                  '${language == 'fr' ? 'Moyenne par transaction' : 'Average per transaction'}: ${NumberFormat('#,##0').format(_calculateAverageTransaction(sales))} RWF',
                  style: pw.TextStyle(font: font, fontSize: 14),
                ),
                pw.SizedBox(height: 20),

                // Sales Details
                if (sales.isNotEmpty) ...[
                  pw.Text(
                    language == 'fr' ? 'Détails des Ventes' : 'Sales Details',
                    style: pw.TextStyle(font: boldFont, fontSize: 18),
                  ),
                  pw.SizedBox(height: 10),
                  ...sales.map<pw.Widget>((sale) => 
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2),
                      child: pw.Text(
                        '${sale['productName']} - ${sale['quantity']} x ${NumberFormat('#,##0').format(sale['unitPrice'])} = ${NumberFormat('#,##0').format(sale['totalAmount'])} RWF',
                        style: pw.TextStyle(font: font, fontSize: 10),
                      ),
                    ),
                  ).toList(),
                ],
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      throw Exception('Error generating daily summary: $e');
    }
  }

  double _calculateTotalSales(List<Map<String, dynamic>> sales) {
    return sales.fold<double>(0, (sum, sale) => sum + (sale['totalAmount'] ?? 0));
  }

  double _calculateAverageTransaction(List<Map<String, dynamic>> sales) {
    if (sales.isEmpty) return 0;
    final total = _calculateTotalSales(sales);
    return total / sales.length;
  }

  // Print Sales Summary (for Sales tab)
  Future<void> printSalesSummary(List<Map<String, dynamic>> sales, String language) async {
    final pdf = pw.Document();
    final font = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();

    final totalSales = sales.fold<double>(0, (sum, sale) => sum + (sale['totalAmount'] ?? 0));
    final totalTransactions = sales.length;
    final averageTransaction = totalTransactions > 0 ? totalSales / totalTransactions : 0;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(language == 'fr' ? 'Résumé des Ventes' : 'Sales Summary', style: pw.TextStyle(font: boldFont, fontSize: 24)),
              pw.Text(DateFormat('yyyy-MM-dd').format(DateTime.now()), style: pw.TextStyle(font: font, fontSize: 12)),
              pw.SizedBox(height: 20),
              pw.Text('${language == 'fr' ? 'Ventes totales' : 'Total sales'}: ${NumberFormat('#,##0').format(totalSales)} RWF', style: pw.TextStyle(font: font, fontSize: 14)),
              pw.Text('${language == 'fr' ? 'Nombre de transactions' : 'Number of transactions'}: $totalTransactions', style: pw.TextStyle(font: font, fontSize: 14)),
              pw.Text('${language == 'fr' ? 'Moyenne par transaction' : 'Average per transaction'}: ${NumberFormat('#,##0').format(averageTransaction)} RWF', style: pw.TextStyle(font: font, fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.Text(language == 'fr' ? 'Détails des Ventes' : 'Sales Details', style: pw.TextStyle(font: boldFont, fontSize: 18)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: [
                  language == 'fr' ? 'Date' : 'Date',
                  language == 'fr' ? 'Produit' : 'Product',
                  language == 'fr' ? 'Qté' : 'Qty',
                  language == 'fr' ? 'Total' : 'Total',
                  language == 'fr' ? 'Paiement' : 'Payment',
                  language == 'fr' ? 'Client' : 'Customer',
                ],
                data: sales.map((sale) => [
                  sale['createdAt'] != null ? DateFormat('yyyy-MM-dd').format((sale['createdAt'] as Timestamp).toDate()) : '',
                  sale['productName'] ?? '',
                  sale['quantity']?.toString() ?? '',
                  NumberFormat('#,##0').format(sale['totalAmount'] ?? 0),
                  sale['paymentMethod'] ?? '',
                  sale['customerName'] ?? '',
                ]).toList(),
                cellStyle: pw.TextStyle(font: font, fontSize: 10),
                headerStyle: pw.TextStyle(font: boldFont, fontSize: 11),
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignment: pw.Alignment.centerLeft,
                columnWidths: {0: const pw.FlexColumnWidth(1.2)},
              ),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  // Print Finance Summary (for Finance tab)
  Future<void> printFinanceSummary(Map<String, dynamic> financeData, String language) async {
    final pdf = pw.Document();
    final font = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();

    final revenue = financeData['revenue'] ?? 0;
    final expenses = financeData['expenses'] ?? 0;
    final profit = financeData['profit'] ?? 0;
    final margin = financeData['margin'] ?? 0;
    final costBreakdown = financeData['costBreakdown'] as Map<String, dynamic>? ?? {};

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(language == 'fr' ? 'Résumé Financier' : 'Finance Summary', style: pw.TextStyle(font: boldFont, fontSize: 24)),
              pw.Text(DateFormat('yyyy-MM-dd').format(DateTime.now()), style: pw.TextStyle(font: font, fontSize: 12)),
              pw.SizedBox(height: 20),
              pw.Text('${language == 'fr' ? 'Revenus' : 'Revenue'}: ${NumberFormat('#,##0').format(revenue)} RWF', style: pw.TextStyle(font: font, fontSize: 14)),
              pw.Text('${language == 'fr' ? 'Dépenses' : 'Expenses'}: ${NumberFormat('#,##0').format(expenses)} RWF', style: pw.TextStyle(font: font, fontSize: 14)),
              pw.Text('${language == 'fr' ? 'Profit' : 'Profit'}: ${NumberFormat('#,##0').format(profit)} RWF', style: pw.TextStyle(font: font, fontSize: 14)),
              pw.Text('${language == 'fr' ? 'Marge' : 'Margin'}: $margin%', style: pw.TextStyle(font: font, fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.Text(language == 'fr' ? 'Répartition des Coûts' : 'Cost Breakdown', style: pw.TextStyle(font: boldFont, fontSize: 18)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: [language == 'fr' ? 'Catégorie' : 'Category', language == 'fr' ? 'Montant' : 'Amount'],
                data: costBreakdown.entries.map((e) => [e.key, NumberFormat('#,##0').format(e.value)]).toList(),
                cellStyle: pw.TextStyle(font: font, fontSize: 10),
                headerStyle: pw.TextStyle(font: boldFont, fontSize: 11),
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
} 
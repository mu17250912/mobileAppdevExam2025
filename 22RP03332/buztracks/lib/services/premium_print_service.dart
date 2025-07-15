import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'subscription_service.dart';

class PremiumPrintService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SubscriptionService _subscriptionService = SubscriptionService();

  String? get currentUserId => _auth.currentUser?.uid;

  // Print methods for the reports screen
  Future<void> printBusinessReport({
    required List<Map<String, dynamic>> sales,
    required List<Map<String, dynamic>> products,
    required Map<String, dynamic> financeData,
    String language = 'en',
  }) async {
    try {
      final pdfBytes = await generatePremiumBusinessReport(
        sales: sales,
        products: products,
        financeData: financeData,
        language: language,
        includePredictions: true,
      );
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      throw Exception('Failed to print business report: $e');
    }
  }

  Future<void> printSalesReport(Map<String, dynamic>? analytics) async {
    try {
      final pdfBytes = await generatePremiumBusinessReport(
        language: 'fr', // Default to French
        includePredictions: false,
      );
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      throw Exception('Failed to print sales report: $e');
    }
  }

  Future<void> printFinancialReport(Map<String, dynamic>? analytics) async {
    try {
      final pdfBytes = await generatePremiumBusinessReport(
        language: 'fr', // Default to French
        includePredictions: false,
      );
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      throw Exception('Failed to print financial report: $e');
    }
  }

  // Premium Business Report with Advanced Analytics
  Future<Uint8List> generatePremiumBusinessReport({
    List<Map<String, dynamic>> sales = const [],
    List<Map<String, dynamic>> products = const [],
    Map<String, dynamic> financeData = const {},
    DateTime? startDate,
    DateTime? endDate,
    String language = 'en',
    bool includeCharts = true,
    bool includePredictions = true,
  }) async {
    final analytics = await _getAdvancedAnalytics(startDate: startDate, endDate: endDate);
    final pdf = pw.Document();
    final font = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();

    // Cover Page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
                colors: [PdfColors.yellow, PdfColors.orange],
              ),
            ),
            child: pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    language == 'fr' ? 'Rapport d\'Entreprise Premium' : 'Premium Business Report',
                    style: pw.TextStyle(font: boldFont, fontSize: 32, color: PdfColors.black),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    '${DateFormat('dd/MM/yyyy').format(startDate ?? DateTime.now().subtract(Duration(days: 30)))} - ${DateFormat('dd/MM/yyyy').format(endDate ?? DateTime.now())}',
                    style: pw.TextStyle(font: font, fontSize: 16, color: PdfColors.black),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Text(
                    language == 'fr' ? 'Analyse Approfondie et Insights IA' : 'Advanced Analytics & AI Insights',
                    style: pw.TextStyle(font: boldFont, fontSize: 18, color: PdfColors.black),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    // Executive Summary
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                language == 'fr' ? 'Résumé Exécutif' : 'Executive Summary',
                style: pw.TextStyle(font: boldFont, fontSize: 24),
              ),
              pw.SizedBox(height: 20),
              _buildKPISection(analytics, language, font, boldFont),
              pw.SizedBox(height: 20),
              _buildGrowthAnalysis(analytics, language, font, boldFont),
              pw.SizedBox(height: 20),
              _buildRiskAssessment(analytics, language, font, boldFont),
            ],
          );
        },
      ),
    );

    // --- Sales Section ---
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final totalSales = sales.fold<double>(0, (sum, sale) => sum + (sale['totalAmount'] ?? 0));
          final totalTransactions = sales.length;
          final averageTransaction = totalTransactions > 0 ? totalSales / totalTransactions : 0;
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

    // --- Stock Section ---
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final lowStockProducts = products.where((p) => (p['stock'] ?? 0) <= (p['minStock'] ?? 10)).toList();
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                language == 'fr' ? 'Rapport d\'Inventaire' : 'Inventory Report',
                style: pw.TextStyle(font: boldFont, fontSize: 24),
              ),
              pw.Text(
                DateFormat('yyyy-MM-dd').format(DateTime.now()),
                style: pw.TextStyle(font: font, fontSize: 12),
              ),
              pw.SizedBox(height: 20),
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
              pw.Text(
                language == 'fr' ? 'Produits' : 'Products',
                style: pw.TextStyle(font: boldFont, fontSize: 18),
              ),
              pw.SizedBox(height: 10),
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

    // --- Finance Section ---
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final revenue = financeData['revenue'] ?? 0;
          final expenses = financeData['expenses'] ?? 0;
          final profit = financeData['profit'] ?? 0;
          final margin = financeData['margin'] ?? 0;
          final costBreakdown = financeData['costBreakdown'] as Map<String, dynamic>? ?? {};
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

    // --- AI Insights and Predictions (existing) ---
    if (includePredictions) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  language == 'fr' ? 'Insights IA et Prédictions' : 'AI Insights & Predictions',
                  style: pw.TextStyle(font: boldFont, fontSize: 24),
                ),
                pw.SizedBox(height: 20),
                _buildMarketTrends(analytics, language, font, boldFont),
                pw.SizedBox(height: 20),
                _buildRevenuePredictions(analytics, language, font, boldFont),
                pw.SizedBox(height: 20),
                _buildStrategicRecommendations(analytics, language, font, boldFont),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  // Helper methods for building report sections
  pw.Widget _buildKPISection(Map<String, dynamic> analytics, String language, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          language == 'fr' ? 'Indicateurs Clés de Performance' : 'Key Performance Indicators',
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
                      language == 'fr' ? 'Revenus Totaux' : 'Total Revenue',
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
                      language == 'fr' ? 'Croissance' : 'Growth',
                      style: pw.TextStyle(font: font, fontSize: 12),
                    ),
                    pw.Text(
                      '+${analytics['growthRate']?.toStringAsFixed(1) ?? '0'}%',
                      style: pw.TextStyle(font: boldFont, fontSize: 16, color: PdfColors.green),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildGrowthAnalysis(Map<String, dynamic> analytics, String language, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          language == 'fr' ? 'Analyse de Croissance' : 'Growth Analysis',
          style: pw.TextStyle(font: boldFont, fontSize: 16),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          language == 'fr' 
              ? 'Votre entreprise montre une croissance positive avec une augmentation de ${analytics['growthRate']?.toStringAsFixed(1) ?? '0'}% des ventes.'
              : 'Your business shows positive growth with a ${analytics['growthRate']?.toStringAsFixed(1) ?? '0'}% increase in sales.',
          style: pw.TextStyle(font: font, fontSize: 12),
        ),
      ],
    );
  }

  pw.Widget _buildRiskAssessment(Map<String, dynamic> analytics, String language, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          language == 'fr' ? 'Évaluation des Risques' : 'Risk Assessment',
          style: pw.TextStyle(font: boldFont, fontSize: 16),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          language == 'fr' 
              ? 'Points d\'attention identifiés: ${analytics['lowStockProducts']?.length ?? 0} produits en stock faible.'
              : 'Risk factors identified: ${analytics['lowStockProducts']?.length ?? 0} products with low stock.',
          style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.red),
        ),
      ],
    );
  }

  pw.Widget _buildSalesPerformance(Map<String, dynamic> analytics, String language, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          language == 'fr' ? 'Performance des Ventes' : 'Sales Performance',
          style: pw.TextStyle(font: boldFont, fontSize: 16),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          language == 'fr' 
              ? 'Ventes totales: ${NumberFormat('#,##0').format(analytics['totalSales'])} RWF'
              : 'Total sales: ${NumberFormat('#,##0').format(analytics['totalSales'])} RWF',
          style: pw.TextStyle(font: font, fontSize: 12),
        ),
      ],
    );
  }

  pw.Widget _buildCustomerAnalysis(Map<String, dynamic> analytics, String language, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          language == 'fr' ? 'Analyse des Clients' : 'Customer Analysis',
          style: pw.TextStyle(font: boldFont, fontSize: 16),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          language == 'fr' 
              ? 'Nombre total de clients: ${analytics['totalCustomers'] ?? 0}'
              : 'Total customers: ${analytics['totalCustomers'] ?? 0}',
          style: pw.TextStyle(font: font, fontSize: 12),
        ),
      ],
    );
  }

  pw.Widget _buildInventoryAnalysis(Map<String, dynamic> analytics, String language, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          language == 'fr' ? 'Analyse d\'Inventaire' : 'Inventory Analysis',
          style: pw.TextStyle(font: boldFont, fontSize: 16),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          language == 'fr' 
              ? 'Produits en stock: ${analytics['totalProducts'] ?? 0}'
              : 'Products in stock: ${analytics['totalProducts'] ?? 0}',
          style: pw.TextStyle(font: font, fontSize: 12),
        ),
      ],
    );
  }

  pw.Widget _buildMarketTrends(Map<String, dynamic> analytics, String language, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          language == 'fr' ? 'Tendances du Marché' : 'Market Trends',
          style: pw.TextStyle(font: boldFont, fontSize: 16),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          language == 'fr' 
              ? 'Analyse des tendances du marché basée sur les données de vente.'
              : 'Market trend analysis based on sales data.',
          style: pw.TextStyle(font: font, fontSize: 12),
        ),
      ],
    );
  }

  pw.Widget _buildRevenuePredictions(Map<String, dynamic> analytics, String language, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          language == 'fr' ? 'Prédictions de Revenus' : 'Revenue Predictions',
          style: pw.TextStyle(font: boldFont, fontSize: 16),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          language == 'fr' 
              ? 'Prédiction de revenus pour le prochain mois: ${NumberFormat('#,##0').format(analytics['predictedRevenue'] ?? 0)} RWF'
              : 'Revenue prediction for next month: ${NumberFormat('#,##0').format(analytics['predictedRevenue'] ?? 0)} RWF',
          style: pw.TextStyle(font: font, fontSize: 12),
        ),
      ],
    );
  }

  pw.Widget _buildStrategicRecommendations(Map<String, dynamic> analytics, String language, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          language == 'fr' ? 'Recommandations Stratégiques' : 'Strategic Recommendations',
          style: pw.TextStyle(font: boldFont, fontSize: 16),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          language == 'fr' 
              ? 'Recommandations basées sur l\'analyse des données et les tendances du marché.'
              : 'Recommendations based on data analysis and market trends.',
          style: pw.TextStyle(font: font, fontSize: 12),
        ),
      ],
    );
  }

  // Helper method to get advanced analytics data
  Future<Map<String, dynamic>> _getAdvancedAnalytics({DateTime? startDate, DateTime? endDate}) async {
    // Simulate getting analytics data from Firestore
    return {
      'totalSales': 125000,
      'totalTransactions': 89,
      'averageTransaction': 1404,
      'growthRate': 12.5,
      'totalCustomers': 45,
      'totalProducts': 67,
      'lowStockProducts': ['Product A', 'Product B'],
      'predictedRevenue': 135000,
      'dailySales': {
        '2024-01-01': 4500,
        '2024-01-02': 5200,
        '2024-01-03': 4800,
        '2024-01-04': 6100,
        '2024-01-05': 5800,
        '2024-01-06': 7200,
        '2024-01-07': 6800,
      },
    };
  }

  double _calculateTotalInventoryValue(List<Map<String, dynamic>> products) {
    return products.fold<double>(0, (sum, product) => sum + ((product['stock'] ?? 0) * (product['price'] ?? 0)));
  }
} 
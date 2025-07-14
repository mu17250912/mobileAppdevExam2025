import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'custom_top_bar.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class TransactionScreen extends StatelessWidget {
  final String? userEmail;
  TransactionScreen({Key? key, this.userEmail}) : super(key: key);
  final Color headerColor = const Color(0xFF2575FC);
  final Color evenRowColor = Color(0xFFF5F7FB);
  final Color oddRowColor = Color(0xFFFFFFFF);

  Future<List<Map<String, dynamic>>> _fetchPayments() async {
    final snap = await FirebaseFirestore.instance
        .collection('payments')
        .orderBy('timestamp', descending: true)
        .get();
    return snap.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchSavings() async {
    final snap = await FirebaseFirestore.instance
        .collection('savings')
        .orderBy('timestamp', descending: true)
        .get();
    return snap.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<pw.Document> _generatePdf() async {
    final payments = await _fetchPayments();
    final savings = await _fetchSavings();
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Payment Transactions',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          payments.isEmpty
              ? pw.Text('No payment transactions found.')
              : pw.Table.fromTextArray(
                  headers: [
                    'Cardholder Name',
                    'Card Number',
                    'Expiry',
                    'CVV',
                    'Save Details',
                    'Timestamp',
                  ],
                  data: payments
                      .map(
                        (data) => [
                          data['cardholderName'] ?? '',
                          data['cardNumber'] ?? '',
                          data['expiry'] ?? '',
                          data['cvv'] ?? '',
                          data['saveDetails']?.toString() ?? '',
                          data['timestamp'] != null
                              ? data['timestamp'].toDate().toString()
                              : '',
                        ],
                      )
                      .toList(),
                ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Savings Transactions',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          savings.isEmpty
              ? pw.Text('No savings transactions found.')
              : pw.Table.fromTextArray(
                  headers: ['Bank Name', 'Bank ID', 'Amount', 'Timestamp'],
                  data: savings
                      .map(
                        (data) => [
                          data['bankName'] ?? '',
                          data['bankId'] ?? '',
                          data['amount']?.toString() ?? '',
                          data['timestamp'] != null
                              ? data['timestamp'].toDate().toString()
                              : '',
                        ],
                      )
                      .toList(),
                ),
        ],
      ),
    );
    return pdf;
  }

  void _onPrint(BuildContext context) async {
    final pdf = await _generatePdf();
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void _onDownload(BuildContext context) async {
    final pdf = await _generatePdf();
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/transactions.pdf');
    await file.writeAsBytes(bytes);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('PDF downloaded to: ${file.path}')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        centerTitle: false,
        title: CustomTopBar(pageName: 'Transaction', userEmail: userEmail),
        actions: [
          IconButton(
            icon: Icon(Icons.print, color: Colors.orange),
            tooltip: 'Print Transactions',
            onPressed: () => _onPrint(context),
          ),
          IconButton(
            icon: Icon(Icons.download, color: Colors.orange),
            tooltip: 'Download Transactions',
            onPressed: () => _onDownload(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Transactions',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildPaymentsTable(context),
              const SizedBox(height: 32),
              Text(
                'Savings Transactions',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildSavingsTable(context),
              const SizedBox(height: 32),
              Text(
                'Card Transactions',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildCardsTable(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentsTable(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 340,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('payments')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: \\${snapshot.error}'));
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(child: Text('No payment transactions found.'));
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    headerColor.withOpacity(0.9),
                  ),
                  headingTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  dataRowHeight: 48,
                  columns: const [
                    DataColumn(
                      label: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Cardholder Name'),
                      ),
                    ),
                    DataColumn(
                      label: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Card Number'),
                      ),
                    ),
                    DataColumn(
                      label: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Expiry'),
                      ),
                    ),
                    DataColumn(
                      label: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('CVV'),
                      ),
                    ),
                    DataColumn(
                      label: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Save Details'),
                      ),
                    ),
                    DataColumn(
                      label: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Timestamp'),
                      ),
                    ),
                  ],
                  rows: List.generate(docs.length, (i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final rowColor = i % 2 == 0 ? evenRowColor : oddRowColor;
                    return DataRow(
                      color: MaterialStateProperty.all(rowColor),
                      cells: [
                        DataCell(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              data['cardholderName']?.toString() ?? '',
                            ),
                          ),
                        ),
                        DataCell(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(data['cardNumber']?.toString() ?? ''),
                          ),
                        ),
                        DataCell(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(data['expiry']?.toString() ?? ''),
                          ),
                        ),
                        DataCell(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(data['cvv']?.toString() ?? ''),
                          ),
                        ),
                        DataCell(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(data['saveDetails']?.toString() ?? ''),
                          ),
                        ),
                        DataCell(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              data['timestamp'] != null &&
                                      data['timestamp'] is Timestamp
                                  ? (data['timestamp'] as Timestamp)
                                        .toDate()
                                        .toString()
                                  : '',
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSavingsTable(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 340,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('savings')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: \\${snapshot.error}'));
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(child: Text('No savings transactions found.'));
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    headerColor.withOpacity(0.9),
                  ),
                  headingTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  dataRowHeight: 48,
                  columns: const [
                    DataColumn(
                      label: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Bank Name'),
                      ),
                    ),
                    DataColumn(
                      label: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Bank ID'),
                      ),
                    ),
                    DataColumn(
                      label: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Amount'),
                      ),
                    ),
                    DataColumn(
                      label: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Timestamp'),
                      ),
                    ),
                  ],
                  rows: List.generate(docs.length, (i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final rowColor = i % 2 == 0 ? evenRowColor : oddRowColor;
                    return DataRow(
                      color: MaterialStateProperty.all(rowColor),
                      cells: [
                        DataCell(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(data['bankName']?.toString() ?? ''),
                          ),
                        ),
                        DataCell(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(data['bankId']?.toString() ?? ''),
                          ),
                        ),
                        DataCell(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(data['amount']?.toString() ?? ''),
                          ),
                        ),
                        DataCell(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              data['timestamp'] != null &&
                                      data['timestamp'] is Timestamp
                                  ? (data['timestamp'] as Timestamp)
                                        .toDate()
                                        .toString()
                                  : '',
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCardsTable(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 340,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Cards')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: \\${snapshot.error}'));
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(child: Text('No card transactions found.'));
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    headerColor.withOpacity(0.9),
                  ),
                  headingTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  dataRowHeight: 48,
                  columns: const [
                    DataColumn(
                      label: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Card Name'),
                      ),
                    ),
                    DataColumn(
                      label: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Card Number'),
                      ),
                    ),
                    DataColumn(
                      label: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Client Name'),
                      ),
                    ),
                    DataColumn(
                      label: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Initial Balance'),
                      ),
                    ),
                    DataColumn(
                      label: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Timestamp'),
                      ),
                    ),
                  ],
                  rows: List.generate(docs.length, (i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final rowColor = i % 2 == 0 ? evenRowColor : oddRowColor;
                    return DataRow(
                      color: MaterialStateProperty.all(rowColor),
                      cells: [
                        DataCell(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(data['cardName']?.toString() ?? ''),
                          ),
                        ),
                        DataCell(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(data['cardNumber']?.toString() ?? ''),
                          ),
                        ),
                        DataCell(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(data['clientName']?.toString() ?? ''),
                          ),
                        ),
                        DataCell(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(data['initialBalance']?.toString() ?? ''),
                          ),
                        ),
                        DataCell(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              data['timestamp'] != null && data['timestamp'] is Timestamp
                                  ? (data['timestamp'] as Timestamp).toDate().toString()
                                  : '',
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

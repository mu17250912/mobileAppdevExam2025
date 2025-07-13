import 'package:flutter/material.dart';
import 'custom_top_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class CardScreen extends StatefulWidget {
  final String? userEmail;
  const CardScreen({Key? key, this.userEmail}) : super(key: key);

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  void _showPaymentDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String? selectedBank = 'bpr bank';
    final TextEditingController bankIdController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Row(
                children: const [
                  Icon(Icons.payment, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Saving', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: Form(
                key: _formKey,
                child: SizedBox(
                  width: 320,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedBank,
                        decoration: const InputDecoration(
                          labelText: 'Bank Name',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            ['bpr bank', 'BK bank', 'I & M bank', 'Equity bank']
                                .map(
                                  (bank) => DropdownMenuItem(
                                    value: bank,
                                    child: Text(bank),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) => setState(() => selectedBank = val),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: bankIdController,
                        decoration: const InputDecoration(
                          labelText: 'Bank ID',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter Bank ID' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Amount to Save',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter amount' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  icon: isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(Icons.payment, color: Colors.white),
                  label: Text(isLoading ? 'Processing...' : 'Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => isLoading = true);
                          // Store data in Firestore
                          try {
                            await FirebaseFirestore.instance
                                .collection('savings')
                                .add({
                                  'bankName': selectedBank,
                                  'bankId': bankIdController.text.trim(),
                                  'amount': amountController.text.trim(),
                                  'timestamp': FieldValue.serverTimestamp(),
                                });
                            await Future.delayed(const Duration(seconds: 3));
                          } catch (e) {
                            // Optionally show error
                          }
                          setState(() => isLoading = false);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Saving successfully'),
                            ),
                          );
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomTopBar(
        pageName: 'My Card Using',
        userEmail: widget.userEmail,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/cards.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 700),
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth < 600 ? 1 : 2;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.4,
                  children: [
                    buildCard(
                      context: context,
                      title: 'bpr Bank Saving ',
                      amount: ' 4 75,890,000',
                      number: '**** 1234',
                      expiry: '1/4',
                      logoPath: 'assets/images/bpr.png',
                      colors: [Colors.green.shade700, Colors.blueGrey.shade900],
                    ),
                    buildCard(
                      context: context,
                      title: 'I & BM Bank Saving',
                      amount: ' 4 548,003,060',
                      number: '**** 1234',
                      expiry: '2/4',
                      logoPath: 'assets/images/ibm.png',
                      colors: [Colors.red.shade800, Colors.black87],
                    ),
                    buildCard(
                      context: context,
                      title: 'bk Bank Saving',
                      amount: ' 4 250,058',
                      number: '**** 1234',
                      expiry: '3/4',
                      logoPath: 'assets/images/bkk.png',
                      colors: [Colors.deepPurple, Colors.indigo.shade900],
                    ),
                    buildCard(
                      context: context,
                      title: 'Equity Bank Saving',
                      amount: ' 4 548,003,065',
                      number: '**** 1234',
                      expiry: '4/4',
                      logoPath: 'assets/images/eqt.png',
                      colors: [Colors.blue.shade700, Colors.black87],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.add_card),
        label: Text('Add Card'),
        backgroundColor: Colors.orange,
        onPressed: () => _showAddCardDialog(context),
      ),
    );
  }

  void _showAddCardDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String? selectedCard = 'bk Card';
    final TextEditingController cardNumberController = TextEditingController();
    final TextEditingController clientNameController = TextEditingController();
    final TextEditingController initialBalanceController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Row(
                children: const [
                  Icon(Icons.credit_card, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Add Card', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: Form(
                key: _formKey,
                child: SizedBox(
                  width: 320,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedCard,
                        decoration: const InputDecoration(
                          labelText: 'Card Name',
                          prefixIcon: Icon(Icons.account_balance),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'bk Card',
                          'Equit Card',
                          'I & MB Card',
                          'brp Card',
                        ].map((card) => DropdownMenuItem(
                              value: card,
                              child: Text(card),
                            )).toList(),
                        onChanged: (val) => setState(() => selectedCard = val),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: cardNumberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Card Number',
                          prefixIcon: Icon(Icons.numbers),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Enter Card Number' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: clientNameController,
                        decoration: const InputDecoration(
                          labelText: 'Client Name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Enter Client Name' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: initialBalanceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        decoration: const InputDecoration(
                          labelText: 'Initial Balance',
                          prefixIcon: Icon(Icons.account_balance_wallet),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Enter Initial Balance' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  icon: isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(Icons.add_card, color: Colors.white),
                  label: Text(isLoading ? 'Processing...' : 'Submit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => isLoading = true);
                          try {
                            await FirebaseFirestore.instance
                                .collection('Cards')
                                .add({
                              'cardName': selectedCard,
                              'cardNumber': cardNumberController.text.trim(),
                              'clientName': clientNameController.text.trim(),
                              'initialBalance': initialBalanceController.text.trim(),
                              'timestamp': FieldValue.serverTimestamp(),
                            });
                            await Future.delayed(const Duration(seconds: 3));
                          } catch (e) {
                            // Optionally show error
                          }
                          setState(() => isLoading = false);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Successfully added Card'),
                            ),
                          );
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget buildCard({
    required BuildContext context,
    required String title,
    required String amount,
    required String number,
    required String expiry,
    required String logoPath,
    required List<Color> colors,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 4)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Bank + payment icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.white70)),
              GestureDetector(
                onTap: () => _showPaymentDialog(context),
                child: Icon(Icons.payment, color: Colors.orange, size: 22),
              ),
            ],
          ),
          Spacer(),
          // Amount
          Text(
            amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Spacer(),
          // Card number and expiry
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(number, style: TextStyle(color: Colors.white70)),
              Text(expiry, style: TextStyle(color: Colors.white70)),
            ],
          ),
          SizedBox(height: 8),
          // Logo at bottom right
          Align(
            alignment: Alignment.bottomRight,
            child: Image.asset(logoPath, width: 40),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class ContractsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final contracts = [
      {'title': 'Loan Agreement', 'signed': false},
      {'title': 'Payment Plan', 'signed': true},
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Contracts')),
      body: ListView.builder(
        itemCount: contracts.length,
        itemBuilder: (context, index) {
          final contract = contracts[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              leading: Icon(Icons.description, color: Colors.deepPurple),
              title: Text(contract['title'] as String),
              subtitle: Text((contract['signed'] as bool) ? 'Signed' : 'Pending Signature'),
              trailing: (contract['signed'] as bool)
                  ? Icon(Icons.check_circle, color: Colors.green)
                  : ElevatedButton(
                      child: Text('Sign'),
                      onPressed: () {
                        // TODO: Implement digital signing logic
                      },
                    ),
              onTap: () {
                // TODO: View or download contract
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Upload new contract
        },
        child: Icon(Icons.upload_file),
        tooltip: 'Upload Contract',
      ),
    );
  }
} 
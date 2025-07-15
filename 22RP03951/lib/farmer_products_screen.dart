import 'package:flutter/material.dart';

class FarmerProductsScreen extends StatelessWidget {
  final String farmerName;
  const FarmerProductsScreen({Key? key, required this.farmerName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with actual fetching and display of farmer's products
    return Scaffold(
      appBar: AppBar(
        title: Text('Products by $farmerName'),
      ),
      body: Center(
        child: Text('All products by $farmerName will be shown here.'),
      ),
    );
  }
} 
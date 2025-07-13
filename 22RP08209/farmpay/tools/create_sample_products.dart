import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  // Initialize Firebase (you'll need to configure this)
  // Firebase.initializeApp();
  
  final firestore = FirebaseFirestore.instance;
  
  // Sample products with realistic pricing in RWF
  final List<Map<String, dynamic>> sampleProducts = [
    {
      'name': 'NPK 17-17-17 Balanced Fertilizer',
      'category': 'Balanced',
      'price': 2500.0, // RWF per kg
      'description': 'Complete balanced fertilizer for all crops',
      'image_url': 'https://example.com/npk.jpg',
      'stock': 1000,
      'unit': 'kg',
    },
    {
      'name': 'Urea Nitrogen Fertilizer',
      'category': 'Nitrogen',
      'price': 1800.0, // RWF per kg
      'description': 'High nitrogen fertilizer for leafy growth',
      'image_url': 'https://example.com/urea.jpg',
      'stock': 800,
      'unit': 'kg',
    },
    {
      'name': 'DAP Phosphate Fertilizer',
      'category': 'Phosphate',
      'price': 2200.0, // RWF per kg
      'description': 'Phosphate fertilizer for root development',
      'image_url': 'https://example.com/dap.jpg',
      'stock': 600,
      'unit': 'kg',
    },
    {
      'name': 'Potassium Sulfate',
      'category': 'Potassium',
      'price': 2800.0, // RWF per kg
      'description': 'Potassium fertilizer for fruit quality',
      'image_url': 'https://example.com/potassium.jpg',
      'stock': 500,
      'unit': 'kg',
    },
    {
      'name': 'Organic Compost',
      'category': 'Organic',
      'price': 1500.0, // RWF per kg
      'description': 'Natural organic fertilizer',
      'image_url': 'https://example.com/compost.jpg',
      'stock': 2000,
      'unit': 'kg',
    },
    {
      'name': 'Zinc Sulfate Micronutrient',
      'category': 'Micronutrients',
      'price': 3500.0, // RWF per kg
      'description': 'Zinc micronutrient for crop health',
      'image_url': 'https://example.com/zinc.jpg',
      'stock': 300,
      'unit': 'kg',
    },
    {
      'name': 'Calcium Nitrate',
      'category': 'Nitrogen',
      'price': 3200.0, // RWF per kg
      'description': 'Calcium and nitrogen combination',
      'image_url': 'https://example.com/calcium.jpg',
      'stock': 400,
      'unit': 'kg',
    },
    {
      'name': 'Triple Super Phosphate',
      'category': 'Phosphate',
      'price': 2400.0, // RWF per kg
      'description': 'High phosphate content fertilizer',
      'image_url': 'https://example.com/tsp.jpg',
      'stock': 700,
      'unit': 'kg',
    },
  ];

  try {
    print('Adding sample products to Firestore...');
    
    for (final product in sampleProducts) {
      await firestore.collection('products').add(product);
      print('Added: ${product['name']} - RWF ${product['price']}/kg');
    }
    
    print('Successfully added ${sampleProducts.length} sample products!');
    print('\nSample pricing:');
    print('- NPK Balanced: RWF 2,500/kg');
    print('- Urea Nitrogen: RWF 1,800/kg');
    print('- DAP Phosphate: RWF 2,200/kg');
    print('- Potassium: RWF 2,800/kg');
    print('- Organic Compost: RWF 1,500/kg');
    print('- Micronutrients: RWF 3,500/kg');
    
  } catch (e) {
    print('Error adding sample products: $e');
  }
} 
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  String? _vendorEmail;
  String _vendorType = 'abcd company ltd';
  String _vendorLocation = 'xxx';
  String? _userId;

  List<Map<String, dynamic>> goods = [];
  final List<String> _titles = [
    'Overview',
    'My Goods',
    'Orders',
    'Profile',
    'My Stories',
  ];
  List<String> _vendorProductNames = [];
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _vendorEmail = user?.email;
      _userId = user?.uid;
    });
    _fetchVendorProfile();
    _fetchVendorProducts();
    _fetchPremiumStatus();
  }

  Future<void> _fetchVendorProfile() async {
    if (_userId != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_userId).get();
      setState(() {
        _vendorType = doc.data()?['type'] ?? 'abcd company ltd';
        _vendorLocation = doc.data()?['location'] ?? 'xxx';
      });
    }
  }

  Future<void> _fetchVendorProducts() async {
    if (_userId != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('vendorId', isEqualTo: _userId)
          .get();
      setState(() {
        _vendorProductNames = snapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    }
  }

  Future<void> _fetchPremiumStatus() async {
    if (_userId != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_userId).get();
      setState(() {
        _isPremium = doc.data()?['isPremium'] == true;
      });
    }
  }

  void _showEditVendorProfile() {
    final typeController = TextEditingController(text: _vendorType);
    final locationController = TextEditingController(text: _vendorLocation);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Company Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: typeController,
              decoration: const InputDecoration(
                labelText: 'Company Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newType = typeController.text.trim();
              final newLocation = locationController.text.trim();
              if (_userId != null) {
                await FirebaseFirestore.instance.collection('users').doc(_userId).update({
                  'type': newType,
                  'location': newLocation,
                });
                setState(() {
                  _vendorType = newType;
                  _vendorLocation = newLocation;
                });
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Company info updated!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showGoPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Premium'),
        content: SizedBox(
          width: 350,
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Unlock unlimited product listings and more!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.star, color: Colors.orange, size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Premium Price: 5,000 FRW',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Choose your payment method:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  physics: AlwaysScrollableScrollPhysics(),
                  children: [
                    _buildPaymentOption(
                      icon: Icons.phone_android,
                      title: 'MTN Mobile Money',
                      subtitle: 'Pay via MTN Mobile Money',
                      color: Colors.yellow.shade700,
                      onTap: () => _processPayment('MTN Mobile Money'),
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentOption(
                      icon: Icons.phone_android,
                      title: 'Airtel Money',
                      subtitle: 'Pay via Airtel Money',
                      color: Colors.red.shade600,
                      onTap: () => _processPayment('Airtel Money'),
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentOption(
                      icon: Icons.credit_card,
                      title: 'Credit/Debit Card',
                      subtitle: 'Pay with Visa, Mastercard, etc.',
                      color: Colors.blue.shade600,
                      onTap: () => _processPayment('Credit/Debit Card'),
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentOption(
                      icon: Icons.account_balance,
                      title: 'Bank Transfer',
                      subtitle: 'Direct bank transfer',
                      color: Colors.green.shade600,
                      onTap: () => _processPayment('Bank Transfer'),
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentOption(
                      icon: Icons.paypal,
                      title: 'PayPal',
                      subtitle: 'Pay with PayPal account',
                      color: Colors.indigo.shade600,
                      onTap: () => _processPayment('PayPal'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Future<void> _processPayment(String paymentMethod) async {
    Navigator.pop(context); // Close the payment method selection dialog
    
    // Show payment details dialog based on method
    final result = await _showPaymentDetailsDialog(paymentMethod);
    
    if (result == true) {
      // Show processing dialog (auto-close after 2 seconds)
      await _showProcessingDialog(paymentMethod);
      
      // Update premium status
      if (_userId != null) {
        await FirebaseFirestore.instance.collection('users').doc(_userId).update({'isPremium': true});
        setState(() {
          _isPremium = true;
        });
      }
      
      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment successful via $paymentMethod! You are now a Premium Vendor!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<bool?> _showPaymentDetailsDialog(String paymentMethod) async {
    final phoneController = TextEditingController();
    final cardNumberController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();
    final bankAccountController = TextEditingController();
    final paypalEmailController = TextEditingController();

    Widget paymentFields;
    String dialogTitle;
    
    switch (paymentMethod) {
      case 'MTN Mobile Money':
      case 'Airtel Money':
        dialogTitle = '$paymentMethod Payment';
        paymentFields = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Enter $paymentMethod Number',
                prefixText: '+250 ',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Amount: 5,000 FRW\nYou will receive a payment prompt on your phone.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        break;
        
      case 'Credit/Debit Card':
        dialogTitle = 'Card Payment';
        paymentFields = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cardNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Card Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: expiryController,
                    decoration: const InputDecoration(
                      labelText: 'MM/YY',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: cvvController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.security, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Amount: 5,000 FRW\nYour payment is secured with SSL encryption.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        break;
        
      case 'Bank Transfer':
        dialogTitle = 'Bank Transfer';
        paymentFields = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: bankAccountController,
              decoration: const InputDecoration(
                labelText: 'Account Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Bank Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('Bank: Rwanda Commercial Bank'),
                  Text('Account: 1234567890'),
                  Text('Amount: 5,000 FRW'),
                  Text('Reference: Premium Upgrade'),
                ],
              ),
            ),
          ],
        );
        break;
        
      case 'PayPal':
        dialogTitle = 'PayPal Payment';
        paymentFields = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: paypalEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'PayPal Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.paypal, color: Colors.indigo),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Amount: 5,000 FRW\nYou will be redirected to PayPal to complete payment.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        break;
        
      default:
        dialogTitle = 'Payment';
        paymentFields = const Text('Payment method not supported');
    }

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dialogTitle),
        content: paymentFields,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Validate required fields based on payment method
              bool isValid = false;
              switch (paymentMethod) {
                case 'MTN Mobile Money':
                case 'Airtel Money':
                  isValid = phoneController.text.trim().isNotEmpty;
                  break;
                case 'Credit/Debit Card':
                  isValid = cardNumberController.text.trim().isNotEmpty &&
                           expiryController.text.trim().isNotEmpty &&
                           cvvController.text.trim().isNotEmpty;
                  break;
                case 'Bank Transfer':
                  isValid = bankAccountController.text.trim().isNotEmpty;
                  break;
                case 'PayPal':
                  isValid = paypalEmailController.text.trim().isNotEmpty;
                  break;
              }
              
              if (!isValid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all required fields.')),
                );
                return;
              }
              
              Navigator.pop(context, true);
            },
            child: const Text('Proceed to Payment'),
          ),
        ],
      ),
    );
  }

  Future<void> _showProcessingDialog(String paymentMethod) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Processing Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Processing $paymentMethod payment...'),
            const SizedBox(height: 8),
            const Text(
              'Please wait while we process your payment.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _addProduct() {
    if (!_isPremium && goods.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Free vendors can only add up to 3 products. Upgrade to Premium for unlimited listings!')),
      );
      return;
    }
    final _nameController = TextEditingController();
    final _priceController = TextEditingController();
    // List of available images with a placeholder
    final List<String> imageOptions = [
      '', // Placeholder for 'Select product image'
      'assets/images/cityfoods.png',
      'assets/images/kigaliFood.png',
      'assets/images/allfoood.png',
      'assets/images/inyama_y_inka.png',
      'assets/images/ifiriti.png',
      'assets/images/platefood.png',
      'assets/images/books.png',
      'assets/images/plates.png',
      'assets/images/logo1.png',
    ];
    String selectedImage = imageOptions[0];
    bool _inStock = true;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price (FRW)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                // Image picker dropdown with placeholder
                DropdownButtonFormField<String>(
                  value: selectedImage,
                  decoration: const InputDecoration(labelText: 'Product Image'),
                  items: imageOptions.map((img) => DropdownMenuItem(
                    value: img,
                    child: img.isEmpty
                      ? const Text('Select product image')
                      : Row(
                          children: [
                            Image.asset(img, width: 36, height: 36),
                            const SizedBox(width: 8),
                            Text(img.split('/').last),
                          ],
                        ),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedImage = val);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _inStock,
                      onChanged: (val) {
                        setState(() => _inStock = val ?? true);
                      },
                    ),
                    const Text('In Stock'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                final price = int.tryParse(_priceController.text.trim()) ?? 0;
                if (name.isNotEmpty && price > 0 && _userId != null && selectedImage.isNotEmpty) {
                  final productData = {
                    'name': name,
                    'price': price,
                    'inStock': _inStock,
                    'image': selectedImage,
                    'vendorId': _userId,
                    'vendorEmail': _vendorEmail,
                    'createdAt': FieldValue.serverTimestamp(),
                  };
                  try {
                    final doc = await FirebaseFirestore.instance.collection('products').add(productData);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Product added to Firestore!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add product: $e')),
                    );
                  }
                } else if (selectedImage.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a product image.')),
                  );
                }
              },
              child: const Text('Add Product'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome, $_vendorType!',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Location: $_vendorLocation',
            style: const TextStyle(fontSize: 18, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showEditVendorProfile,
            icon: const Icon(Icons.edit),
            label: const Text('Edit Company Info'),
          ),
          if (!_isPremium) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showGoPremiumDialog,
              icon: const Icon(Icons.star, color: Colors.amber),
              label: const Text('Go Premium'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
          ],
          const SizedBox(height: 24),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: _userId == null
                        ? null
                        : FirebaseFirestore.instance
                            .collection('products')
                            .where('vendorId', isEqualTo: _userId)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Total Products: ...');
                      }
                      if (!snapshot.hasData) {
                        return const Text('Total Products: 0');
                      }
                      final count = snapshot.data!.docs.length;
                      return Text('Total Products: $count', style: const TextStyle(fontSize: 18));
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoods() {
    if (_userId == null) {
      return const Center(child: Text('Not logged in.'));
    }
    final List<String> imageOptions = [
      '',
      'assets/images/cityfoods.png',
      'assets/images/kigaliFood.png',
      'assets/images/allfoood.png',
      'assets/images/inyama_y_inka.png',
      'assets/images/ifiriti.png',
      'assets/images/platefood.png',
      'assets/images/books.png',
      'assets/images/plates.png',
      'assets/images/logo1.png',
    ];
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('vendorId', isEqualTo: _userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No products found.'));
        }
        goods = snapshot.data!.docs.map((doc) => {
          ...doc.data() as Map<String, dynamic>,
          'reference': doc.reference,
        }).toList();
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: goods.length,
          itemBuilder: (context, index) {
            final product = goods[index];
            final docRef = product['reference'] as DocumentReference;
            return Card(
              child: ListTile(
                leading: Image.asset(product['image'], width: 50, height: 50, fit: BoxFit.cover),
                title: Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Price: ${product['price']} FRW\n${product['inStock'] ? 'In Stock' : 'Out of Stock'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        // Show edit dialog
                        final nameController = TextEditingController(text: product['name']);
                        final priceController = TextEditingController(text: product['price'].toString());
                        String selectedImage = product['image'] ?? imageOptions[0];
                        bool inStock = product['inStock'] ?? true;
                        showDialog(
                          context: context,
                          builder: (context) => StatefulBuilder(
                            builder: (context, setState) => AlertDialog(
                              title: const Text('Edit Product'),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: nameController,
                                      decoration: const InputDecoration(labelText: 'Product Name'),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: priceController,
                                      decoration: const InputDecoration(labelText: 'Price (FRW)'),
                                      keyboardType: TextInputType.number,
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      value: selectedImage.isNotEmpty ? selectedImage : imageOptions[0],
                                      decoration: const InputDecoration(labelText: 'Product Image'),
                                      items: imageOptions.map((img) => DropdownMenuItem(
                                        value: img,
                                        child: img.isEmpty
                                          ? const Text('Select product image')
                                          : Row(
                                              children: [
                                                Image.asset(img, width: 36, height: 36),
                                                const SizedBox(width: 8),
                                                Text(img.split('/').last),
                                              ],
                                            ),
                                      )).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => selectedImage = val);
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: inStock,
                                          onChanged: (val) {
                                            setState(() => inStock = val ?? true);
                                          },
                                        ),
                                        const Text('In Stock'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    final newName = nameController.text.trim();
                                    final newPrice = int.tryParse(priceController.text.trim()) ?? 0;
                                    if (newName.isNotEmpty && newPrice > 0 && selectedImage.isNotEmpty) {
                                      await docRef.update({
                                        'name': newName,
                                        'price': newPrice,
                                        'image': selectedImage,
                                        'inStock': inStock,
                                      });
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Product updated!')),
                                      );
                                    } else if (selectedImage.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please select a product image.')),
                                      );
                                    }
                                  },
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await docRef.delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Product deleted.')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOrders() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('vendorId', isEqualTo: _userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No orders for your products yet.'));
        }
        final orders = snapshot.data!.docs;
        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index].data() as Map<String, dynamic>;
            final buyerId = order['buyerId'];
            if (buyerId == null) {
              // No buyerId, just show available info
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('Order: ${order['foodName'] ?? ''}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${order['status'] ?? ''}'),
                      Text('Buyer Email: ${order['buyerEmail'] ?? 'Unknown'}'),
                      Text('Order Time: ${order['orderTime'] ?? ''}'),
                      if (order['price'] != null) Text('Price: ${order['price']} FRW'),
                      if (order['price'] != null) Text('Commission (10%): ${(order['price'] * 0.1).toStringAsFixed(0)} FRW'),
                    ],
                  ),
                ),
              );
            } else {
              // Use FutureBuilder to fetch buyer info
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(buyerId).get(),
                builder: (context, userSnapshot) {
                  String buyerEmail = order['buyerEmail'] ?? 'Unknown';
                  String buyerPhone = '';
                  if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                    buyerEmail = userData['email'] ?? buyerEmail;
                    buyerPhone = userData['phone'] ?? '';
                  }
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text('Order: ${order['foodName'] ?? ''}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: ${order['status'] ?? ''}'),
                          Text('Buyer Email: $buyerEmail'),
                          if (buyerPhone.isNotEmpty) Text('Buyer Phone: $buyerPhone'),
                          Text('Order Time: ${order['orderTime'] ?? ''}'),
                          if (order['price'] != null) Text('Price: ${order['price']} FRW'),
                          if (order['price'] != null) Text('Commission (10%): ${(order['price'] * 0.1).toStringAsFixed(0)} FRW'),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        );
      },
    );
  }

  Widget _buildProfile() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(radius: 40, backgroundColor: Colors.deepPurple, child: Icon(Icons.store, size: 40, color: Colors.white)),
          const SizedBox(height: 16),
          Text(
            _vendorEmail ?? 'Vendor',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Vendor Profile Info Here'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _logout,
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildStories() {
    if (_userId == null) {
      return const Center(child: Text('Not logged in.'));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stories')
          .where('vendorId', isEqualTo: _userId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No stories found.'));
        }
        final stories = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: stories.length,
          itemBuilder: (context, index) {
            final story = stories[index].data() as Map<String, dynamic>;
            final docRef = stories[index].reference;
            DateTime? timestamp;
            if (story['timestamp'] != null && story['timestamp'] is Timestamp) {
              timestamp = (story['timestamp'] as Timestamp).toDate();
            } else if (story['localTimestamp'] != null) {
              timestamp = DateTime.tryParse(story['localTimestamp'].toString());
            }
            return Card(
              child: ListTile(
                leading: story['productImage'] != null && story['productImage'].toString().isNotEmpty
                    ? Image.asset(
                        story['productImage'],
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.image, size: 40, color: Colors.grey),
                title: Text(story['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(story['description'] ?? ''),
                    if (story['productName'] != null)
                      Text('Product: ${story['productName']}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                    if (timestamp != null)
                      Text('Posted: ${timestamp.toLocal()}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    if (timestamp == null)
                      const Text('Posted: Just now', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        _showEditStoryDialog(docRef, story);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await docRef.delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Story deleted.')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverview();
      case 1:
        return _buildGoods();
      case 2:
        return _buildOrders();
      case 3:
        return _buildProfile();
      case 4:
        return _buildStories();
      default:
        return _buildOverview();
    }
  }

  void _showAddStoryDialog() {
    final _titleController = TextEditingController();
    final _descController = TextEditingController();
    String? selectedProductName;
    String? selectedProductImage;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Story'),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fetch products for this vendor
                  StreamBuilder<QuerySnapshot>(
                    stream: _userId == null
                        ? null
                        : FirebaseFirestore.instance
                            .collection('products')
                            .where('vendorId', isEqualTo: _userId)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Text('No products found. Add a product first.');
                      }
                      final products = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            value: selectedProductName,
                            decoration: const InputDecoration(labelText: 'Product'),
                            items: products.map((product) {
                              return DropdownMenuItem<String>(
                                value: product['name'],
                                child: Text(product['name'] ?? ''),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                selectedProductName = val;
                                selectedProductImage = products.firstWhere((p) => p['name'] == val)['image'];
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          if (selectedProductImage != null && selectedProductImage!.isNotEmpty)
                            Center(
                              child: Image.asset(
                                selectedProductImage!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 4,
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = _titleController.text.trim();
              final desc = _descController.text.trim();
              if (title.isNotEmpty && desc.isNotEmpty && _userId != null && selectedProductName != null && selectedProductImage != null) {
                try {
                  final storyData = {
                    'title': title,
                    'description': desc,
                    'vendorId': _userId,
                    'vendorEmail': _vendorEmail,
                    'productName': selectedProductName,
                    'productImage': selectedProductImage,
                    'timestamp': FieldValue.serverTimestamp(),
                    'localTimestamp': DateTime.now(),
                  };
                  final storyDoc = await FirebaseFirestore.instance.collection('stories').add(storyData);
                  // Notify all users
                  final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
                  for (final userDoc in usersSnapshot.docs) {
                    await FirebaseFirestore.instance.collection('notifications').add({
                      'userId': userDoc.id,
                      'title': 'New Story',
                      'body': 'New story: \'${storyData['title']}\' has been posted. Check it out!',
                      'timestamp': FieldValue.serverTimestamp(),
                      'read': false,
                      'type': 'story',
                      'storyId': storyDoc.id,
                    });
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Story added!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add story: $e')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields and select a product.')),
                );
              }
            },
            child: const Text('Add Story'),
          ),
        ],
      ),
    );
  }

  void _showEditStoryDialog(DocumentReference docRef, Map<String, dynamic> story) {
    final _titleController = TextEditingController(text: story['title'] ?? '');
    final _descController = TextEditingController(text: story['description'] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Story'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTitle = _titleController.text.trim();
              final newDesc = _descController.text.trim();
              if (newTitle.isNotEmpty && newDesc.isNotEmpty) {
                await docRef.update({
                  'title': newTitle,
                  'description': newDesc,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Story updated!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields.')),
                );
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.deepPurple,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.deepPurple),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(radius: 32, backgroundColor: Colors.white, child: Icon(Icons.store, size: 32, color: Colors.deepPurple)),
                  const SizedBox(height: 12),
                  Text(
                    _vendorEmail ?? 'Vendor',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Overview'),
              selected: _selectedIndex == 0,
              onTap: () {
                Navigator.pop(context);
                _onNavTap(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.fastfood),
              title: const Text('My Goods'),
              selected: _selectedIndex == 1,
              onTap: () {
                Navigator.pop(context);
                _onNavTap(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Orders'),
              selected: _selectedIndex == 2,
              onTap: () {
                Navigator.pop(context);
                _onNavTap(2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              selected: _selectedIndex == 3,
              onTap: () {
                Navigator.pop(context);
                _onNavTap(3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Add Story'),
              onTap: () {
                Navigator.pop(context);
                _showAddStoryDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book),
              title: const Text('My Stories'),
              selected: _selectedIndex == 4,
              onTap: () {
                Navigator.pop(context);
                _onNavTap(4);
              },
            ),
          ],
        ),
      ),
      body: _getBody(),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: _addProduct,
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.add),
              tooltip: 'Add Product',
            )
          : null,
    );
  }
} 
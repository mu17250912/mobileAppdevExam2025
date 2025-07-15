import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../sellers/seller_home.dart';
import '../sellers/register_product_screen.dart';
import '../sellers/manage_products_screen.dart';
import '../sellers/seller_order_tracking_screen.dart';
import '../sellers/seller_chats_screen.dart';
import '../clients/chat_screen.dart';

const Color kPrimaryColor = Color(0xFF6C63FF);
const Color kBackgroundColor = Color(0xFFF5F6FA);
const String kStoreName = 'My Store';
const String kLogoUrl = 'assets/phonestorelogo.jpg';

class SellerSupportScreen extends StatefulWidget {
  const SellerSupportScreen({super.key});

  @override
  State<SellerSupportScreen> createState() => _SellerSupportScreenState();
}

class _SellerSupportScreenState extends State<SellerSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  Future<bool> sendContactEmail({
    required String name,
    required String email,
    required String message,
  }) async {
    const serviceId = 'service_gixckxe';
    const templateId = 'template_cuwqe1w';
    const userId = 'YOUR_PUBLIC_KEY'; // <-- Replace with your actual public key

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost', // or your domain
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {'name': name, 'email': email, 'message': message},
      }),
    );
    return response.statusCode == 200;
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      final success = await sendContactEmail(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        message: _messageController.text.trim(),
      );
      setState(() => _isLoading = false);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(success ? 'Success' : 'Error'),
          content: Text(
            success
                ? 'Your message has been sent!'
                : 'Failed to send message. Please try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (success) {
        _formKey.currentState?.reset();
        _nameController.clear();
        _emailController.clear();
        _messageController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double horizontalPadding = constraints.maxWidth > 600 ? 48 : 12;
        return Scaffold(
          backgroundColor: kBackgroundColor,
          appBar: AppBar(
            backgroundColor: kPrimaryColor,
            elevation: 4,
            titleSpacing: 0,
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(kLogoUrl, width: 40, height: 40, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                const Text(
                  kStoreName,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  accountName: const Text('Seller'),
                  accountEmail: const Text('seller@email.com'),
                  currentAccountPicture: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text('Dashboard'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SellerHomePage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_box),
                  title: const Text('Register Product'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterProductScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.list_alt),
                  title: const Text('Manage Products'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManageProductsScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Orders'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SellerOrderTrackingScreen(sellerId: 'SELLER_ID')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.chat),
                  title: const Text('Chats'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SellerChatsScreen(sellerId: 'SELLER_ID')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.support_agent),
                  title: const Text('Support'),
                  onTap: () {
                    Navigator.pop(context); // Only close the Drawer if already on Support
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () async {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            ),
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value == null || !value.contains('@')
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _messageController,
                    decoration: const InputDecoration(labelText: 'Message'),
                    maxLines: 5,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your message'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Send'),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 0,
            onTap: (index) {
              if (index == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SellerHomePage()),
                );
              } else if (index == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageProductsScreen()),
                );
              } else if (index == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => SellerChatsScreen(sellerId: 'SELLER_ID')),
                );
              }
            },
            selectedItemColor: kPrimaryColor,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
              BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Products'),
              BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
            ],
          ),
        );
      },
    );
  }
}

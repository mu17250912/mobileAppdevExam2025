import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../services/contact_service.dart'; // Import ContactService
import '../views/home_screen.dart'; // Import HomeScreen for navigation
import 'dart:io' show File, Platform;
import '../models/user.dart'; // Correct import for AppUser
// Use ContactRequest and ContactRequestStatus from user.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart'; // Added for image upload
import 'package:url_launcher/url_launcher.dart';

// Define custom colors to match home screen
const Color purple = Color(0xFF8A2BE2);
const Color yellow = Color(0xFFFFD700);
const Color orange = Color(0xFFFF6B35);
const Color teal = Color(0xFF20B2AA);

final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

class RecipeDetailsScreen extends StatefulWidget {
  final Recipe? recipe;
  final String authorId;
  final AppUser currentUser;
  const RecipeDetailsScreen({
    required this.authorId,
    required this.currentUser,
    this.recipe,
    Key? key,
  }) : super(key: key);

  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ingredientsController = TextEditingController();
  String? _videoLink;
  final RecipeService _recipeService = RecipeService();
  bool _isEdit = false;
  bool _isSpecial = false;
  static final Set<String> _chefsWhoPaidForSpecial = {};
  bool _hasPaidForThisSpecial = false;
  bool _showEditForm = false;
  bool _isUploading = false;
  final ContactService _contactService = ContactService();

  // Use the shared contact requests map from contact_service.dart

  @override
  void initState() {
    super.initState();
    _showEditForm = false;
    print('RecipeDetailsScreen: authorId= [0m${widget.authorId}, currentUser=${widget.currentUser}');
    if (widget.recipe != null) {
      print('Editing recipe: title=${widget.recipe!.title}, description=${widget.recipe!.description}');
      _isEdit = true;
      _titleController.text = widget.recipe!.title ?? '';
      _descriptionController.text = widget.recipe!.description ?? '';
      _ingredientsController.text = (widget.recipe!.ingredients ?? <String>[]).join(', ');
      _videoLink = widget.recipe!.videoLink ?? '';
      _isSpecial = widget.recipe!.isSpecial ?? false;
      _hasPaidForThisSpecial = true; // Chef already paid if editing
    } else {
      // Ensure all controllers are initialized to empty
      _titleController.text = '';
      _descriptionController.text = '';
      _ingredientsController.text = '';
      _videoLink = '';
      _isSpecial = false;
      _showEditForm = true; // Only show form for new recipe
      _hasPaidForThisSpecial = false; // Only pay when adding
    }
    // Log view_recipe event
    if (widget.recipe != null) {
    analytics.logEvent(
      name: 'view_recipe',
      parameters: {
        'recipe_id': widget.recipe!.id,
        'recipe_title': widget.recipe!.title,
      },
    );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      print('RecipeDetailsScreen.build: authorId=${widget.authorId}, currentUser=${widget.currentUser}');
      // If _showEditForm is true, show the form. Otherwise, show details view.
      final isEditOrAdd = _showEditForm || widget.recipe == null;
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: purple,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            isEditOrAdd
                ? (_isEdit ? 'Edit Recipe' : 'Add Recipe')
                : 'Recipe Details',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isEditOrAdd ? _buildForm() : _buildDetailsWithActions(),
        ),
      );
    } catch (e, stack) {
      print('Build error: $e\n$stack');
      return Center(child: Text('Unexpected error: $e'));
    }
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Recipe Title',
                  labelStyle: TextStyle(color: purple),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  prefixIcon: Icon(Icons.restaurant, color: purple),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter title' : null,
              ),
            ),
            SizedBox(height: 16),
            
            // Description Field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: purple),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  prefixIcon: Icon(Icons.description, color: purple),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter description' : null,
              ),
            ),
            SizedBox(height: 16),
            
            // Ingredients Field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _ingredientsController,
                decoration: InputDecoration(
                  labelText: 'Ingredients (comma separated)',
                  labelStyle: TextStyle(color: purple),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  prefixIcon: Icon(Icons.list, color: purple),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter ingredients' : null,
              ),
            ),
            SizedBox(height: 24),
            
            // Video Link
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: TextFormField(
                initialValue: _videoLink,
                onChanged: (val) => _videoLink = val,
                decoration: InputDecoration(
                  labelText: 'Video Link (YouTube, etc.)',
                  labelStyle: TextStyle(color: purple),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  prefixIcon: Icon(Icons.link, color: purple),
                ),
              ),
            ),
            SizedBox(height: 24),
            
            // Premium Recipe Option
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _isSpecial,
                        activeColor: purple,
                        onChanged: (val) {
                          setState(() {
                            _isSpecial = val ?? false;
                            _hasPaidForThisSpecial = false;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          'Premium Recipe',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (_isSpecial)
                        ElevatedButton(
                          onPressed: _hasPaidForThisSpecial
                              ? null
                              : () async {
                                  String? paymentMethod;
                                  String? mtnNumber;
                                  bool paymentComplete = false;
                                  // Step 1: Choose payment method
                                  paymentMethod = await showDialog<String>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Choose Payment Method'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            leading: Icon(Icons.account_balance_wallet),
                                            title: Text('PayPal'),
                                            onTap: () => Navigator.of(context).pop('PayPal'),
                                          ),
                                          ListTile(
                                            leading: Icon(Icons.credit_card),
                                            title: Text('Stripe'),
                                            onTap: () => Navigator.of(context).pop('Stripe'),
                                          ),
                                          ListTile(
                                            leading: Icon(Icons.payment),
                                            title: Text('Flutterwave'),
                                            onTap: () => Navigator.of(context).pop('Flutterwave'),
                                          ),
                                          ListTile(
                                            leading: Icon(Icons.phone_android),
                                            title: Text('MTN Mobile Money'),
                                            onTap: () => Navigator.of(context).pop('MTN Mobile Money'),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: Text('Cancel'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (paymentMethod == null) return;
                                  // Step 2: If MTN, prompt for number
                                  if (paymentMethod == 'MTN Mobile Money') {
                                    mtnNumber = await showDialog<String>(
                                      context: context,
                                      builder: (context) {
                                        final controller = TextEditingController();
                                        return AlertDialog(
                                          title: Text('Enter MTN Mobile Money Number'),
                                          content: TextField(
                                            controller: controller,
                                            keyboardType: TextInputType.phone,
                                            decoration: InputDecoration(hintText: '07XXXXXXXX'),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(),
                                              child: Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                                              child: Text('Continue'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    if (mtnNumber == null || mtnNumber.isEmpty) return;
                                  }
                                  // Step 3: Show payment summary
                                  paymentComplete = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Confirm Payment'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Method: $paymentMethod'),
                                          if (mtnNumber != null) Text('MTN Number: $mtnNumber'),
                                          SizedBox(height: 8),
                                          Text('Amount: 500 Frw', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          style: ElevatedButton.styleFrom(backgroundColor: purple),
                                          child: Text('Pay'),
                                        ),
                                      ],
                                    ),
                                  ) ?? false;
                                  if (paymentComplete) {
                                    setState(() {
                                      _hasPaidForThisSpecial = true;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Payment successful! You can now post this premium recipe.'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: yellow,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Pay for Premium'),
                        ),
                    ],
                  ),
                  if (_isSpecial)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Premium recipes are featured prominently and can be monetized',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 32),
            
            // Save Button
            ElevatedButton(
              onPressed: (_isSpecial && !_hasPaidForThisSpecial) || _isUploading
                  ? null
                  : () async {
                      if (widget.authorId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('User information missing. Please log in again.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (_formKey.currentState!.validate()) {
                        setState(() => _isUploading = true);
                        try {
                          print('Starting save: title= [0m${_titleController.text}, desc=${_descriptionController.text}, isSpecial=$_isSpecial');
                          final ingredientsList = _ingredientsController.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();
                          if (widget.recipe != null) {
                            // Editing: update recipe
                            final success = await _recipeService.updateRecipe(
                              widget.recipe!.id,
                              title: _titleController.text.trim(),
                              description: _descriptionController.text.trim(),
                              videoLink: _videoLink?.trim() ?? '',
                              isSpecial: _isSpecial,
                              ingredients: ingredientsList,
                            );
                            print('Update result: $success');
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Recipe updated successfully!'), backgroundColor: Colors.green),
                              );
                              Future.delayed(const Duration(milliseconds: 500), () {
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              });
                            } else {
                              throw Exception('Failed to update recipe.');
                            }
                          } else {
                            // Creating new recipe
                            final recipe = await _recipeService.addRecipe(
                              _titleController.text.trim(),
                              _descriptionController.text.trim(),
                              widget.authorId,
                              videoLink: _videoLink?.trim() ?? '',
                              isSpecial: _isSpecial,
                              ingredients: ingredientsList,
                            );
                            print('Add recipe result: $recipe');
                                ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Recipe added successfully!'), backgroundColor: Colors.green),
                            );
                            Future.delayed(const Duration(milliseconds: 500), () {
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            });
                          }
                        } catch (e, st) {
                          print('Save error: $e\n$st');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        } finally {
                          print('Save finished, setting _isUploading to false');
                          setState(() => _isUploading = false);
                        }
                      } else {
                        print('Form validation failed');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please fill all required fields'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: Text('Save Recipe'),
            ),
            // Add loading indicator below Save button
            if (_isUploading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails() {
    final recipe = widget.recipe!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Default Recipe Image
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/dish.jpg',
                width: 180,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 16),
          // Recipe Title
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.restaurant, color: purple, size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recipe.title,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: purple),
                      ),
                    ),
                    if (recipe.isSpecial)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: yellow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'PREMIUM',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  recipe.description,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          
          // Ingredients
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.list, color: orange, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Ingredients',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: orange),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                if (recipe.ingredients.isNotEmpty)
                  ...recipe.ingredients.map((ing) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.fiber_manual_record, color: orange, size: 8),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ing,
                            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  )).toList()
                else
                  Text('No ingredients listed.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          SizedBox(height: 16),
          
          // Video Information
          if (recipe.videoLink.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.video_library, color: teal, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Video Content',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: teal),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.link, color: teal, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final url = recipe.videoLink;
                            if (await canLaunch(url)) {
                              await launch(url);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Could not launch video link')),
                              );
                            }
                          },
                          child: Text(
                            'Video link: ${recipe.videoLink}',
                            style: TextStyle(fontSize: 14, color: Colors.blue, decoration: TextDecoration.underline),
                          ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailsWithActions() {
    final recipe = widget.recipe!;
    final isAuthor = widget.currentUser != null && recipe.authorId == widget.currentUser!.id;
    final isNotAuthor = widget.currentUser != null && recipe.authorId != widget.currentUser!.id;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetails(),
          SizedBox(height: 24),
          
          // Action Buttons
          if (isNotAuthor)
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.message),
                label: Text('Contact Chef'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: yellow,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final userId = widget.currentUser!.id;
                  final chefId = recipe.authorId;
                  // Check for existing request in Firestore
                  final existingRequests = await _contactService.getContactRequestsForUser(userId).first;
                  final existing = existingRequests.where((r) => r.chefId == chefId && (r.status == ContactRequestStatus.pending || r.status == ContactRequestStatus.approved)).isNotEmpty
                      ? existingRequests.firstWhere((r) => r.chefId == chefId && (r.status == ContactRequestStatus.pending || r.status == ContactRequestStatus.approved))
                      : null;
                  if (existing != null) {
                    if (existing.status == ContactRequestStatus.pending) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('You have already sent a contact request to this chef. Please wait for approval.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    } else if (existing.status == ContactRequestStatus.approved) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Your contact request was already approved!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      return;
                    }
                  }
                  // Add a new request if none exists or if previous was rejected
                  try {
                    await _contactService.sendContactRequest(userId, chefId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Contact request sent!'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to send contact request: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ),
          
          if (isAuthor) ...[
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.edit),
                    label: Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      setState(() {
                        _showEditForm = true;
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.delete),
                    label: Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Delete Recipe'),
                          content: Text('Are you sure you want to delete this recipe? This action cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        try {
                          await _recipeService.deleteRecipe(recipe.id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Recipe deleted successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context, true);
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error deleting recipe: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
} 
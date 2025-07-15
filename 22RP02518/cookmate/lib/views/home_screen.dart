import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/recipe.dart';
import 'recipe_details_screen.dart';
import 'profile_screen.dart';
import 'auth_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../services/recipe_service.dart';

class HomeScreen extends StatefulWidget {
  final AppUser currentUser;
  const HomeScreen({required this.currentUser, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _recipeSearch = '';
  String _chefSearch = '';
  static final Set<String> _usersWithPremium = {};
  bool get _hasPremium => _usersWithPremium.contains(widget.currentUser.id);
  static final Map<String, Set<String>> _userPaidSpecialRecipes = {};
  bool _hasPaidForRecipe(String recipeId) {
    return _userPaidSpecialRecipes[widget.currentUser.id]?.contains(recipeId) ?? false;
  }
  void _markRecipeAsPaid(String recipeId) {
    _userPaidSpecialRecipes.putIfAbsent(widget.currentUser.id, () => <String>{}).add(recipeId);
  }

  // In-memory analytics and contact management (can be expanded to Firestore if needed)
  final RecipeService _recipeService = RecipeService();
  static final Map<String, List<ContactRequest>> _chefContactRequests = {}; // chefId -> requests

  void _incrementRecipeView(String recipeId) {
    _recipeService.incrementRecipeViews(recipeId);
  }

  void _sendContactRequest(String chefId) {
    final userId = widget.currentUser.id;
    final requests = _chefContactRequests.putIfAbsent(chefId, () => []);
    if (!requests.any((r) => r.userId == userId && r.status == ContactRequestStatus.pending)) {
      requests.add(ContactRequest(userId: userId, chefId: chefId));
    }
  }

  List<ContactRequest> _getChefRequests(String chefId) {
    return _chefContactRequests[chefId] ?? [];
  }

  List<ContactRequest> _getUserRequests(String userId) {
    return _chefContactRequests.values.expand((list) => list).where((r) => r.userId == userId).toList();
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Widget _userRecipesScreen() {
    final isChef = widget.currentUser.role == 'chef';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search recipes...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onChanged: (val) => setState(() => _recipeSearch = val),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('recipes').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No recipes yet. Add one!'));
              }
              final recipes = snapshot.data!.docs
                  .map((doc) => Recipe.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                  .where((r) => isChef ? true : !r.isSpecial)
                  .where((r) => r.title.toLowerCase().contains(_recipeSearch.toLowerCase()))
                  .toList();
              return GridView.builder(
                padding: EdgeInsets.all(12),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220, // was 140
                  crossAxisSpacing: 16, // was 4
                  mainAxisSpacing: 16, // was 4
                  childAspectRatio: 0.8, // was 0.95
                ),
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return GestureDetector(
                    onTap: null,
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          // Default Recipe Image
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0), // reduced top padding
                            child: ClipRRect(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                              child: Image.asset(
                                'assets/images/dish.jpg',
                                width: 110,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    recipe.title,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(widget.currentUser.id)
                                      .collection('favorites')
                                      .doc(recipe.id)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    final isFavorite = snapshot.data?.exists ?? false;
                                    return IconButton(
                                      icon: Icon(
                                        isFavorite ? Icons.star : Icons.star_border,
                                        color: isFavorite ? Colors.amber : Colors.grey,
                                      ),
                                      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
                                      onPressed: () async {
                                        final favRef = FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(widget.currentUser.id)
                                            .collection('favorites')
                                            .doc(recipe.id);
                                        if (isFavorite) {
                                          await favRef.delete();
                                        } else {
                                          await favRef.set({
                                            'recipeId': recipe.id,
                                            'title': recipe.title,
                                            'addedAt': FieldValue.serverTimestamp(),
                                          });
                                        }
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0), // add bottom padding
                            child: SizedBox(
                              width: 90,
                              height: 32,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  padding: EdgeInsets.zero,
                                  textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  elevation: 0,
                                ),
                                onPressed: () async {
                                  _incrementRecipeView(recipe.id);
                                  final isSpecial = recipe.isSpecial;
                                  final isOwnRecipe = recipe.authorId == widget.currentUser.id;
                                  if (isSpecial && !isOwnRecipe && !_hasPaidForRecipe(recipe.id)) {
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
                                            Text('Amount: 1000 Frw', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.of(context).pop(true),
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                                            child: Text('Pay'),
                                          ),
                                        ],
                                      ),
                                    ) ?? false;
                                    if (paymentComplete) {
                                      setState(() {
                                        _markRecipeAsPaid(recipe.id);
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Recipe unlocked! Enjoy this special recipe.'), backgroundColor: Colors.green),
                                      );
                                    } else {
                                      return;
                                    }
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RecipeDetailsScreen(recipe: recipe, authorId: recipe.authorId, currentUser: widget.currentUser),
                                    ),
                                  );
                                },
                                child: Text('View'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _chefListScreen() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search chefs...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onChanged: (val) => setState(() => _chefSearch = val),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'chef').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No chefs available.'));
              }
              final chefs = snapshot.data!.docs
                  .map((doc) => AppUser(
                        id: doc['id'],
                        name: doc['name'],
                        email: doc['email'],
                        role: doc['role'],
                      ))
                  .where((c) => c.name.toLowerCase().contains(_chefSearch.toLowerCase()) || c.email.toLowerCase().contains(_chefSearch.toLowerCase()))
                  .toList();
              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: chefs.length,
                itemBuilder: (context, index) {
                  final chef = chefs[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.yellow[700],
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(chef.name, style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(chef.email),
                      trailing: ElevatedButton(
                        onPressed: () {
                          _sendContactRequest(chef.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Contact request sent!'), backgroundColor: Colors.blue),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow[700],
                          foregroundColor: Colors.black,
                          shape: StadiumBorder(),
                        ),
                        child: Text('Contact Chef'),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _specialScreen() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('recipes').where('isSpecial', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No special recipes available yet.'));
        }
        final premiumRecipes = snapshot.data!.docs
            .map((doc) => Recipe.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        return GridView.builder(
          padding: EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: premiumRecipes.length,
          itemBuilder: (context, index) {
            final recipe = premiumRecipes[index];
            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.asset(
                        'assets/images/dish.jpg',
                        width: 110,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                    child: Text(
                      recipe.title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    height: 32,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        padding: EdgeInsets.zero,
                        textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        _incrementRecipeView(recipe.id);
                        if (!_hasPaidForRecipe(recipe.id)) {
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
                                  Text('Amount: 1000 Frw', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                                  child: Text('Pay'),
                                ),
                              ],
                            ),
                          ) ?? false;
                          if (paymentComplete) {
                            setState(() {
                              _markRecipeAsPaid(recipe.id);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Recipe unlocked! Enjoy this special recipe.'), backgroundColor: Colors.green),
                            );
                          } else {
                            return;
                          }
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecipeDetailsScreen(recipe: recipe, authorId: recipe.authorId, currentUser: widget.currentUser),
                          ),
                        );
                      },
                      child: Text('View'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _chefMyRecipesScreen() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('recipes').where('authorId', isEqualTo: widget.currentUser.id).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('You have not added any recipes yet.'));
        }
        final recipes = snapshot.data!.docs
            .map((doc) => Recipe.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        return GridView.builder(
          padding: EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            return GestureDetector(
              onTap: null,
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.asset(
                          'assets/images/dish.jpg',
                          width: 110,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                      child: Text(
                        recipe.title,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      height: 32,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          padding: EdgeInsets.zero,
                          textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailsScreen(recipe: recipe, authorId: recipe.authorId, currentUser: widget.currentUser),
                            ),
                          );
                          if (result != null) setState(() {});
                        },
                        child: Text('View'),
                      ),
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

  Widget _chefAddRecipeScreen() {
    return Center(
      child: ElevatedButton.icon(
        icon: Icon(Icons.add),
        label: Text('Add New Recipe'),
        style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
        onPressed: () async {
          final newRecipe = await Navigator.push<Recipe?>(
            context,
            MaterialPageRoute(
              builder: (_) => RecipeDetailsScreen(recipe: null, authorId: widget.currentUser.id, currentUser: widget.currentUser),
            ),
          );
          if (newRecipe != null) setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.currentUser.role == 'user';
    final isChef = widget.currentUser.role == 'chef';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: Text(isUser
            ? (_currentIndex == 0
                ? 'Recipes'
                : _currentIndex == 1
                    ? 'Chefs'
                    : _currentIndex == 2
                        ? 'Special'
                        : 'Profile')
            : isChef
                ? (_currentIndex == 0
                    ? 'Home'
                    : _currentIndex == 1
                        ? 'My Recipes'
                        : _currentIndex == 2
                            ? 'Add Recipe'
                            : 'Profile')
                : 'CookMate'),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: Icon(Icons.logout, color: Colors.white),
            label: Text('Logout', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Confirm Logout'),
                  content: Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('Logout', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              if (shouldLogout == true) _logout();
            },
          ),
        ],
      ),
      body: isUser
          ? (_currentIndex == 0
              ? _userRecipesScreen()
              : _currentIndex == 1
                  ? _chefListScreen()
                  : _currentIndex == 2
                      ? _specialScreen()
                      : ProfileScreen(
                          user: widget.currentUser,
                          allowEdit: true,
                          recipeViews: const {}, // No longer tracking views in memory
                          getChefRequests: _getChefRequests,
                          getUserRequests: _getUserRequests,
                          getUserById: (id) => null, // Not used with Firestore
                          allRecipes: const [], // Not used with Firestore
                        ))
          : isChef
              ? (_currentIndex == 0
                  ? _userRecipesScreen() // Home: all recipes
                  : _currentIndex == 1
                      ? _chefMyRecipesScreen() // My Recipes: only chef's recipes
                      : _currentIndex == 2
                          ? _chefListScreen() // Chefs: list of all chefs
                          : ProfileScreen(
                              user: widget.currentUser,
                              allowEdit: true,
                              recipeViews: const {}, // No longer tracking views in memory
                              getChefRequests: _getChefRequests,
                              getUserRequests: _getUserRequests,
                              getUserById: (id) => null, // Not used with Firestore
                              allRecipes: const [], // Not used with Firestore
                            ))
              : Center(child: Text('Unknown role')),
      floatingActionButton: isChef && (_currentIndex == 0 || _currentIndex == 1)
          ? FloatingActionButton(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.deepPurple,
              onPressed: () async {
                final newRecipe = await Navigator.push<Recipe?>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecipeDetailsScreen(
                      recipe: null,
                      authorId: widget.currentUser.id,
                      currentUser: widget.currentUser,
                    ),
                  ),
                );
                if (newRecipe != null) setState(() {});
              },
              child: Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: isUser
          ? BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              backgroundColor: Colors.deepPurple,
              selectedItemColor: Colors.amber,
              unselectedItemColor: Colors.white,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Recipes'),
                BottomNavigationBarItem(icon: Icon(Icons.emoji_people), label: 'Chefs'),
                BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Special'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
              ],
            )
          : isChef
              ? BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (i) => setState(() => _currentIndex = i),
                  backgroundColor: Colors.deepPurple,
                  selectedItemColor: Colors.amber,
                  unselectedItemColor: Colors.white,
                  type: BottomNavigationBarType.fixed,
                  items: const [
                    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                    BottomNavigationBarItem(icon: Icon(Icons.book), label: 'My Recipes'),
                    BottomNavigationBarItem(icon: Icon(Icons.emoji_people), label: 'Chefs'),
                    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                  ],
                )
              : null,
    );
  }
} 
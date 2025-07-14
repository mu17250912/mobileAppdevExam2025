import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';
import '../models/user.dart';
import 'recipe_details_screen.dart';

class FavoriteRecipesScreen extends StatelessWidget {
  final AppUser user;
  const FavoriteRecipesScreen({required this.user, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Favorites'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .collection('favorites')
            .orderBy('addedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(child: Text('No favorite recipes yet.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final fav = docs[index].data() as Map<String, dynamic>;
              final recipeId = fav['recipeId'] ?? '';
              final title = fav['title'] ?? '';
              return ListTile(
                leading: Icon(Icons.star, color: Colors.amber),
                title: Text(title),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  // Fetch recipe details from Firestore
                  final recipeDoc = await FirebaseFirestore.instance.collection('recipes').doc(recipeId).get();
                  if (recipeDoc.exists) {
                    final recipe = Recipe.fromMap(recipeDoc.data() as Map<String, dynamic>, recipeDoc.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecipeDetailsScreen(
                          recipe: recipe,
                          authorId: recipe.authorId,
                          currentUser: user,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Recipe not found.'), backgroundColor: Colors.red),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
} 
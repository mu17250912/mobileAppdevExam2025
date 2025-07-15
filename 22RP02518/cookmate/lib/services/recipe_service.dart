import '../models/recipe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Add a new recipe
  Future<Recipe> addRecipe(
    String title,
    String description,
    String authorId, {
    String videoLink = '',
    List<String> ingredients = const [],
    bool isSpecial = false,
  }) async {
    try {
      // Create recipe document
      final docRef = await _firestore.collection('recipes').add({
        'title': title,
        'description': description,
        'authorId': authorId,
        'videoLink': videoLink,
        'ingredients': ingredients,
        'isSpecial': isSpecial,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'views': 0, // initialize views
      });

      // Create recipe object with the generated ID
      final recipe = Recipe(
        id: docRef.id,
        title: title,
        description: description,
        authorId: authorId,
        videoLink: videoLink,
        ingredients: ingredients,
        isSpecial: isSpecial,
      );

      return recipe;
    } catch (e) {
      print('Error adding recipe: $e');
      throw Exception('Failed to add recipe: $e');
    }
  }

  // Increment recipe views in Firestore
  Future<void> incrementRecipeViews(String recipeId) async {
    await _firestore.collection('recipes').doc(recipeId).update({
      'views': FieldValue.increment(1),
    });
  }

  // Get all recipes
  Stream<List<Recipe>> getAllRecipes() {
    return _firestore
        .collection('recipes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Recipe.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get recipes by author
  Stream<List<Recipe>> getRecipesByAuthor(String authorId) {
    return _firestore
        .collection('recipes')
        .where('authorId', isEqualTo: authorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Recipe.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get premium recipes
  Stream<List<Recipe>> getPremiumRecipes() {
    return _firestore
        .collection('recipes')
        .where('isSpecial', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Recipe.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get non-premium recipes
  Stream<List<Recipe>> getNonPremiumRecipes() {
    return _firestore
        .collection('recipes')
        .where('isSpecial', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Recipe.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Update a recipe
  Future<bool> updateRecipe(String id, {String? title, String? description, String? authorId, String? videoLink, List<String>? ingredients, bool? isSpecial}) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (authorId != null) updateData['authorId'] = authorId;
      if (videoLink != null) updateData['videoLink'] = videoLink;
      if (ingredients != null) updateData['ingredients'] = ingredients;
      if (isSpecial != null) updateData['isSpecial'] = isSpecial;

      await _firestore.collection('recipes').doc(id).update(updateData);
      return true;
    } catch (e) {
      print('Error updating recipe: $e');
      return false;
    }
  }

  // Delete a recipe
  Future<bool> deleteRecipe(String id) async {
    try {
      await _firestore.collection('recipes').doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting recipe: $e');
      return false;
    }
  }
} 
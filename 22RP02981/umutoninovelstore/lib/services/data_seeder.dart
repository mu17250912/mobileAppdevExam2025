import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class DataSeeder {
  final FirebaseService _firebaseService = FirebaseService();

  // Seed all collections with initial data
  Future<void> seedAllData() async {
    try {
      print('Starting to seed Firebase collections...');
      
      await seedCategories();
      await seedBooks();
      
      print('✅ All data seeded successfully!');
    } catch (e) {
      print('❌ Error seeding data: $e');
      rethrow;
    }
  }

  // Seed categories
  Future<void> seedCategories() async {
    try {
      print('Seeding categories...');
      
      final categories = [
        {
          'name': 'Novel',
          'description': 'Fictional prose narrative of considerable length',
          'icon': '📚',
          'color': '#4CAF50',
        },
        {
          'name': 'Self-love',
          'description': 'Books about personal development and self-improvement',
          'icon': '💝',
          'color': '#FF9800',
        },
        {
          'name': 'Science',
          'description': 'Scientific literature and research',
          'icon': '🔬',
          'color': '#2196F3',
        },
        {
          'name': 'Romance',
          'description': 'Love stories and romantic fiction',
          'icon': '💕',
          'color': '#E91E63',
        },
        {
          'name': 'Crime',
          'description': 'Mystery, thriller, and crime fiction',
          'icon': '🕵️',
          'color': '#9C27B0',
        },
        {
          'name': 'Fantasy',
          'description': 'Imaginative fiction with magical elements',
          'icon': '🐉',
          'color': '#FF5722',
        },
        {
          'name': 'Biography',
          'description': 'Life stories of real people',
          'icon': '👤',
          'color': '#607D8B',
        },
        {
          'name': 'History',
          'description': 'Historical accounts and events',
          'icon': '📜',
          'color': '#795548',
        },
      ];

      for (var category in categories) {
        await _firebaseService.addCategory(category);
      }
      
      print('✅ Categories seeded successfully!');
    } catch (e) {
      print('❌ Error seeding categories: $e');
      rethrow;
    }
  }

  // Seed books
  Future<void> seedBooks() async {
    try {
      print('Seeding books...');
      
      final books = [
        {
          'title': 'The Catcher in the Rye',
          'author': 'J.D. Salinger',
          'category': 'Novel',
          'description': 'A classic coming-of-age story about teenage alienation and loss of innocence in post-World War II America.',
          'price': 14.05,
          'currency': '₣',
          'imageUrl': 'assets/images/catcher.jpg',
          'isbn': '9780316769488',
          'pages': 277,
          'language': 'English',
          'publishedYear': 1951,
          'publisher': 'Little, Brown and Company',
          'rating': 4.2,
          'reviewCount': 1250,
          'isAvailable': true,
          'isFeatured': true,
          'tags': ['classic', 'coming-of-age', 'american-literature'],
        },
        {
          'title': 'Someone Like You',
          'author': 'Roald Dahl',
          'category': 'Short Stories',
          'description': 'A collection of dark and twisted short stories that showcase Dahl\'s mastery of the macabre.',
          'price': 12.99,
          'currency': '₣',
          'imageUrl': 'assets/images/someone.jpg',
          'isbn': '9780141304700',
          'pages': 224,
          'language': 'English',
          'publishedYear': 1953,
          'publisher': 'Alfred A. Knopf',
          'rating': 4.0,
          'reviewCount': 890,
          'isAvailable': true,
          'isFeatured': false,
          'tags': ['short-stories', 'dark', 'macabre'],
        },
        {
          'title': 'The Lord of the Rings',
          'author': 'J.R.R. Tolkien',
          'category': 'Fantasy',
          'description': 'An epic high-fantasy novel about the quest to destroy a powerful ring and save Middle-earth from darkness.',
          'price': 25.50,
          'currency': '₣',
          'imageUrl': 'assets/images/lord.jpg',
          'isbn': '9780547928210',
          'pages': 1216,
          'language': 'English',
          'publishedYear': 1954,
          'publisher': 'Allen & Unwin',
          'rating': 4.8,
          'reviewCount': 2100,
          'isAvailable': true,
          'isFeatured': true,
          'tags': ['fantasy', 'epic', 'adventure', 'classic'],
        },
        {
          'title': 'The Power of Now',
          'author': 'Eckhart Tolle',
          'category': 'Self-love',
          'description': 'A guide to spiritual enlightenment that teaches readers how to live in the present moment.',
          'price': 16.99,
          'currency': '₣',
          'imageUrl': 'assets/images/home_illustration.png',
          'isbn': '9781577314806',
          'pages': 236,
          'language': 'English',
          'publishedYear': 1997,
          'publisher': 'New World Library',
          'rating': 4.3,
          'reviewCount': 1560,
          'isAvailable': true,
          'isFeatured': false,
          'tags': ['spirituality', 'mindfulness', 'self-help'],
        },
        {
          'title': 'A Brief History of Time',
          'author': 'Stephen Hawking',
          'category': 'Science',
          'description': 'A landmark volume in science writing that explores the mysteries of the universe.',
          'price': 18.75,
          'currency': '₣',
          'imageUrl': 'assets/images/home_illustration.png',
          'isbn': '9780553380163',
          'pages': 256,
          'language': 'English',
          'publishedYear': 1988,
          'publisher': 'Bantam Books',
          'rating': 4.4,
          'reviewCount': 980,
          'isAvailable': true,
          'isFeatured': true,
          'tags': ['physics', 'cosmology', 'science'],
        },
        {
          'title': 'Pride and Prejudice',
          'author': 'Jane Austen',
          'category': 'Romance',
          'description': 'A classic romance novel about the relationship between Elizabeth Bennet and Mr. Darcy.',
          'price': 13.25,
          'currency': '₣',
          'imageUrl': 'assets/images/home_illustration.png',
          'isbn': '9780141439518',
          'pages': 432,
          'language': 'English',
          'publishedYear': 1813,
          'publisher': 'T. Egerton',
          'rating': 4.5,
          'reviewCount': 1800,
          'isAvailable': true,
          'isFeatured': false,
          'tags': ['romance', 'classic', 'historical-fiction'],
        },
        {
          'title': 'The Girl with the Dragon Tattoo',
          'author': 'Stieg Larsson',
          'category': 'Crime',
          'description': 'A gripping crime thriller about a journalist and a computer hacker investigating a 40-year-old disappearance.',
          'price': 15.99,
          'currency': '₣',
          'imageUrl': 'assets/images/home_illustration.png',
          'isbn': '9780307454541',
          'pages': 672,
          'language': 'English',
          'publishedYear': 2005,
          'publisher': 'Norstedts Förlag',
          'rating': 4.1,
          'reviewCount': 1200,
          'isAvailable': true,
          'isFeatured': false,
          'tags': ['thriller', 'mystery', 'crime'],
        },
        {
          'title': 'Steve Jobs',
          'author': 'Walter Isaacson',
          'category': 'Biography',
          'description': 'The definitive biography of Apple\'s visionary co-founder, based on more than forty interviews.',
          'price': 19.99,
          'currency': '₣',
          'imageUrl': 'assets/images/home_illustration.png',
          'isbn': '9781451648539',
          'pages': 656,
          'language': 'English',
          'publishedYear': 2011,
          'publisher': 'Simon & Schuster',
          'rating': 4.2,
          'reviewCount': 950,
          'isAvailable': true,
          'isFeatured': true,
          'tags': ['biography', 'technology', 'apple'],
        },
        {
          'title': 'Sapiens: A Brief History of Humankind',
          'author': 'Yuval Noah Harari',
          'category': 'History',
          'description': 'A groundbreaking narrative of humanity\'s creation and evolution that explores the ways biology and history have defined us.',
          'price': 22.50,
          'currency': '₣',
          'imageUrl': 'assets/images/home_illustration.png',
          'isbn': '9780062316097',
          'pages': 464,
          'language': 'English',
          'publishedYear': 2011,
          'publisher': 'Harper',
          'rating': 4.6,
          'reviewCount': 1400,
          'isAvailable': true,
          'isFeatured': false,
          'tags': ['history', 'anthropology', 'evolution'],
        },
        {
          'title': 'The Alchemist',
          'author': 'Paulo Coelho',
          'category': 'Novel',
          'description': 'A magical story about following your dreams and listening to your heart.',
          'price': 11.99,
          'currency': '₣',
          'imageUrl': 'assets/images/home_illustration.png',
          'isbn': '9780062315007',
          'pages': 208,
          'language': 'English',
          'publishedYear': 1988,
          'publisher': 'HarperOne',
          'rating': 4.3,
          'reviewCount': 2100,
          'isAvailable': true,
          'isFeatured': true,
          'tags': ['inspirational', 'adventure', 'philosophy'],
        },
      ];

      for (var book in books) {
        await _firebaseService.addBook(book);
      }
      
      print('✅ Books seeded successfully!');
    } catch (e) {
      print('❌ Error seeding books: $e');
      rethrow;
    }
  }

  // Clear all data (for testing purposes)
  Future<void> clearAllData() async {
    try {
      print('Clearing all data...');
      
      final collections = [
        FirebaseService.booksCollection,
        FirebaseService.categoriesCollection,
        FirebaseService.usersCollection,
        FirebaseService.ordersCollection,
        FirebaseService.favoritesCollection,
        FirebaseService.reviewsCollection,
      ];

      for (var collectionName in collections) {
        final querySnapshot = await FirebaseFirestore.instance.collection(collectionName).get();
        for (var doc in querySnapshot.docs) {
          await doc.reference.delete();
        }
      }
      
      print('✅ All data cleared successfully!');
    } catch (e) {
      print('❌ Error clearing data: $e');
      rethrow;
    }
  }
} 
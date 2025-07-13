// import 'package:flutter/material.dart';
// import 'book_details_screen.dart';

// class BooksScreen extends StatelessWidget {
//   const BooksScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // Placeholder book data
//     final books = [
//       {
//         'title': 'Flutter for Beginners',
//         'cover': 'https://via.placeholder.com/100x150.png?text=Book+1',
//       },
//       {
//         'title': 'Advanced Dart',
//         'cover': 'https://via.placeholder.com/100x150.png?text=Book+2',
//       },
//       {
//         'title': 'Firebase Essentials',
//         'cover': 'https://via.placeholder.com/100x150.png?text=Book+3',
//       },
//     ];

//     return Scaffold(
//       appBar: AppBar(title: const Text('Books')),
//       body: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: books.length,
//         itemBuilder: (context, index) {
//           final book = books[index];
//           return Card(
//             margin: const EdgeInsets.symmetric(vertical: 8),
//             child: ListTile(
//               leading: Image.network(book['cover']!, width: 50, height: 75, fit: BoxFit.cover),
//               title: Text(book['title']!),
//               trailing: ElevatedButton(
//                 child: const Text('Details'),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => BookDetailsScreen(
//                         title: book['title']!,
//                         coverUrl: book['cover']!,
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// } 
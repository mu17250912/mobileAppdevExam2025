import 'package:flutter/material.dart';

class FirebaseSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  @override
  Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  @override
  Widget buildResults(BuildContext context) => Center(child: Text('Search: $query'));
  @override
  Widget buildSuggestions(BuildContext context) => Container();
} 
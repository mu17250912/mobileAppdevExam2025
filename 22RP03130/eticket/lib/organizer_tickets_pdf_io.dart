import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

Future<void> exportTicketsPdf(BuildContext context, List<int> bytes, String filename) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$filename');
  await file.writeAsBytes(bytes);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('PDF file saved: ${file.path}')),
  );
} 
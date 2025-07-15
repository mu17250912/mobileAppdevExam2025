import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> exportTicketsPdf(BuildContext context, List<int> bytes, String filename) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('PDF download started!')),
  );
} 
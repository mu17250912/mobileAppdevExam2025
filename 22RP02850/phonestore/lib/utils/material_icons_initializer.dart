import 'package:flutter/material.dart';

/// Initialize Material Icons
Future<void> initializeMaterialIcons(BuildContext context) async {
  // Initialize Material Icons font
  await precacheImage(const AssetImage('packages/cupertino_icons/assets/CupertinoIcons.ttf'), context);
}

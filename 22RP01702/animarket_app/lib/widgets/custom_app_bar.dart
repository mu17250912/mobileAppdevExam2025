import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showBack = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: kPrimaryGreen,
      elevation: 0,
      leading: showBack ? BackButton(color: Colors.white) : null,
      title: Text(title, style: TextStyle(color: Colors.white)),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

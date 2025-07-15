import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final bool isOffline;
  final bool isDarkMode;
  final void Function(bool, bool) onChanged;

  const SettingsScreen({
    Key? key,
    required this.isOffline,
    required this.isDarkMode,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool isOffline;
  late bool isDarkMode;

  @override
  void initState() {
    super.initState();
    isOffline = widget.isOffline;
    isDarkMode = widget.isDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Offline Reading'),
            subtitle: const Text('Enable offline book reading'),
            value: isOffline,
            onChanged: (value) {
              setState(() => isOffline = value);
              widget.onChanged(isOffline, isDarkMode);
            },
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: isDarkMode,
            onChanged: (value) {
              setState(() => isDarkMode = value);
              widget.onChanged(isOffline, isDarkMode);
            },
          ),
        ],
      ),
    );
  }
}

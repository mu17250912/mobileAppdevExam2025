import 'package:flutter/material.dart';
import 'theme_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _selectedTemplate;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    final template = await ThemeService.getCurrentTemplate();
    setState(() {
      _selectedTemplate = template;
      _loading = false;
    });
  }

  Future<void> _saveTemplate(String template) async {
    await ThemeService.setTemplate(template);
    setState(() {
      _selectedTemplate = template;
    });
    final templateData = ThemeService.getTemplateData(template);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Theme "$template" applied successfully!'),
        backgroundColor: templateData['primaryColor'],
      ),
    );

    // Navigate back to refresh the main app
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Map<String, dynamic> get _currentTemplate {
    return ThemeService.getTemplateData(_selectedTemplate ?? 'Elegant Purple');
  }

  @override
  Widget build(BuildContext context) {
    final currentTemplate = _currentTemplate;
    final templates = ThemeService.getAllTemplates();

    return Scaffold(
      backgroundColor: currentTemplate['backgroundColor'],
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: currentTemplate['appBarColor'],
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Your Theme:',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: currentTemplate['primaryColor'],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select a theme to personalize your app appearance and experience',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ...templates.map((template) => _buildTemplateCard(template)),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: currentTemplate['cardColor'],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: currentTemplate['primaryColor'],
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: currentTemplate['primaryColor'],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active Theme',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                currentTemplate['name'] ?? 'Elegant Purple',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: currentTemplate['primaryColor'],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your app is currently using this theme',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template) {
    final isSelected = template['name'] == _selectedTemplate;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isSelected
            ? template['primaryColor'].withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? template['primaryColor'] : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _saveTemplate(template['name']),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: template['primaryColor'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: template['primaryColor'],
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    template['icon'],
                    color: template['primaryColor'],
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template['name'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: template['primaryColor'],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        template['description'],
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: template['primaryColor'],
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

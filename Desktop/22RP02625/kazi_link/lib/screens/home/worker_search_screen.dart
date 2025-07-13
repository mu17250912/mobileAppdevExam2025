import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WorkerSearchScreen extends StatefulWidget {
  const WorkerSearchScreen({super.key});

  @override
  State<WorkerSearchScreen> createState() => _WorkerSearchScreenState();
}

class _WorkerSearchScreenState extends State<WorkerSearchScreen> {
  String selectedCategory = '';
  String selectedLocation = '';

  final List<Map<String, dynamic>> workers = [
    {
      'name': 'Alice Johnson',
      'category': 'Plumber',
      'location': 'Nairobi',
      'rating': 4.9,
      'reviews': 127,
      'experience': '5 years',
      'avatar': 'AJ',
    },
    {
      'name': 'Bob Smith',
      'category': 'Carpenter',
      'location': 'Mombasa',
      'rating': 4.7,
      'reviews': 89,
      'experience': '3 years',
      'avatar': 'BS',
    },
    {
      'name': 'Carol Williams',
      'category': 'Designer',
      'location': 'Nairobi',
      'rating': 4.8,
      'reviews': 156,
      'experience': '7 years',
      'avatar': 'CW',
    },
    {
      'name': 'David Brown',
      'category': 'Plumber',
      'location': 'Kisumu',
      'rating': 4.6,
      'reviews': 73,
      'experience': '4 years',
      'avatar': 'DB',
    },
    {
      'name': 'Emma Davis',
      'category': 'Electrician',
      'location': 'Nairobi',
      'rating': 4.9,
      'reviews': 203,
      'experience': '6 years',
      'avatar': 'ED',
    },
    {
      'name': 'Frank Miller',
      'category': 'Carpenter',
      'location': 'Nakuru',
      'rating': 4.5,
      'reviews': 67,
      'experience': '2 years',
      'avatar': 'FM',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categories = workers.map((w) => w['category']!).toSet().toList();
    final locations = workers.map((w) => w['location']!).toSet().toList();
    final filtered = workers.where((w) {
      final matchCategory = selectedCategory.isEmpty || w['category'] == selectedCategory;
      final matchLocation = selectedLocation.isEmpty || w['location'] == selectedLocation;
      return matchCategory && matchLocation;
    }).toList();
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.1),
                    colorScheme.primary.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.search_rounded,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Find Workers',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      body: Column(
        children: [
          // Search filters
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Workers',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        value: selectedCategory.isEmpty ? null : selectedCategory,
                        hint: 'Category',
                        items: [const DropdownMenuItem(value: '', child: Text('All Categories'))] +
                            categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) => setState(() => selectedCategory = val ?? ''),
                        icon: Icons.category_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown(
                        value: selectedLocation.isEmpty ? null : selectedLocation,
                        hint: 'Location',
                        items: [const DropdownMenuItem(value: '', child: Text('All Locations'))] +
                            locations.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                        onChanged: (val) => setState(() => selectedLocation = val ?? ''),
                        icon: Icons.location_on_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${filtered.length} workers found',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (selectedCategory.isNotEmpty || selectedLocation.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        selectedCategory = '';
                        selectedLocation = '';
                      });
                    },
                    icon: Icon(
                      Icons.clear_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    label: Text(
                      'Clear filters',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Workers list
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(colorScheme)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final worker = filtered[index];
                      return _buildWorkerCard(worker, colorScheme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(
        hint,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      items: items.map((item) => DropdownMenuItem(
        value: item.value,
        child: Text(
          item.child.toString().replaceAll('Text("', '').replaceAll('")', ''),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w400),
        ),
      )).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: colorScheme.primary, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> worker, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shadowColor: colorScheme.shadow.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Navigate to worker profile
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    worker['avatar'],
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Worker info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker['name'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${worker['category']} • ${worker['location']}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${worker['experience']} experience',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Rating
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: Colors.amber.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        worker['rating'].toString(),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${worker['reviews']} reviews',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No workers found',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
} 
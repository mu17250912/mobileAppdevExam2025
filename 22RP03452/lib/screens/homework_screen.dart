import 'package:flutter/material.dart';
import 'homework_detail_screen.dart';

class HomeworkScreen extends StatelessWidget {
  const HomeworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Homework',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF3B82F6)),
            onPressed: () {
              // Handle add homework
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add homework functionality coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter tabs
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterTab('All', true),
                  ),
                  Expanded(
                    child: _buildFilterTab('Pending', false),
                  ),
                  Expanded(
                    child: _buildFilterTab('Completed', false),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 25),
            
            // Homework List
            _buildHomeworkItem(
              context,
              'Math Chapter 5',
              'Complete exercises 1-20 on page 85',
              'Due: Tomorrow',
              'Pending',
              Colors.orange,
              Icons.calculate,
            ),
            _buildHomeworkItem(
              context,
              'Science Project',
              'Research paper on renewable energy',
              'Due: Friday',
              'Assigned',
              Colors.green,
              Icons.science,
            ),
            _buildHomeworkItem(
              context,
              'English Essay',
              'Write a 500-word essay on Shakespeare',
              'Due: Next Week',
              'Overdue',
              Colors.red,
              Icons.edit,
            ),
            _buildHomeworkItem(
              context,
              'History Reading',
              'Read Chapter 8 and answer questions',
              'Due: Yesterday',
              'Completed',
              Colors.blue,
              Icons.book,
            ),
            _buildHomeworkItem(
              context,
              'Art Assignment',
              'Create a landscape painting',
              'Due: Next Month',
              'Assigned',
              Colors.green,
              Icons.palette,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String title, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF3B82F6) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF6B7280),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildHomeworkItem(
    BuildContext context,
    String title,
    String description,
    String dueDate,
    String status,
    Color statusColor,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => HomeworkDetailScreen(
              title: title,
              description: description,
              dueDate: dueDate,
              status: status,
              icon: icon,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: statusColor, size: 24),
            ),
            
            const SizedBox(width: 15),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dueDate,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 15),
            
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
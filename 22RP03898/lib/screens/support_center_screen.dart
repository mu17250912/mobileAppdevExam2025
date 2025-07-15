import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/error_service.dart';

class SupportCenterScreen extends StatefulWidget {
  const SupportCenterScreen({super.key});

  @override
  State<SupportCenterScreen> createState() => _SupportCenterScreenState();
}

class _SupportCenterScreenState extends State<SupportCenterScreen> {
  final AuthService _authService = AuthService();
  final ErrorService _errorService = ErrorService();

  bool _isLoading = true;

  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'How do I book a ride?',
      'answer':
          'Search for available rides, select your preferred option, choose seats, and complete the booking with payment.',
    },
    {
      'question': 'How do I become a driver?',
      'answer':
          'Contact support to apply as a driver. You\'ll need to provide vehicle details and complete verification.',
    },
    {
      'question': 'Can I cancel my booking?',
      'answer':
          'Yes, you can cancel bookings up to 2 hours before departure. Cancellation fees may apply.',
    },
    {
      'question': 'How do I contact my driver?',
      'answer':
          'Use the chat feature in the app or call the driver directly using the provided phone number.',
    },
    {
      'question': 'What payment methods are accepted?',
      'answer':
          'We accept cash, MTN Mobile Money, Airtel Money, and card payments. Premium features require subscription (5,000-15,000 FRW / \$5-\$15 USD).',
    },
    {
      'question': 'How do I report an issue?',
      'answer':
          'Use the "Report Issue" feature in the app or contact our support team directly.',
    },
    {
      'question': 'Is my payment secure?',
      'answer':
          'Yes, all payments are processed securely through our trusted payment partners.',
    },
    {
      'question': 'How do I update my profile?',
      'answer':
          'Go to your profile screen and tap the edit button to update your information.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      await _authService.getCurrentUserModel();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _errorService.logError('Error loading user data in support center', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Center'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildFAQs(),
                  const SizedBox(height: 24),
                  _buildContactSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.support_agent,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'How can we help you?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Find answers to common questions or get in touch with our support team',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withAlpha((0.9 * 255).toInt()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildQuickActionCard(
              icon: Icons.chat,
              title: 'Live Chat',
              subtitle: 'Chat with support',
              onTap: _startLiveChat,
            ),
            _buildQuickActionCard(
              icon: Icons.email,
              title: 'Email Support',
              subtitle: 'Send us an email',
              onTap: _sendEmail,
            ),
            _buildQuickActionCard(
              icon: Icons.phone,
              title: 'Call Support',
              subtitle: 'Speak with us',
              onTap: _callSupport,
            ),
            _buildQuickActionCard(
              icon: Icons.bug_report,
              title: 'Report Issue',
              subtitle: 'Report a problem',
              onTap: _reportIssue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha((0.1 * 255).toInt()),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: Colors.deepPurple.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently Asked Questions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _faqs.length,
          itemBuilder: (context, index) {
            return _buildFAQItem(_faqs[index]);
          },
        ),
      ],
    );
  }

  Widget _buildFAQItem(Map<String, dynamic> faq) {
    return ExpansionTile(
      title: Text(
        faq['question'],
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            faq['answer'],
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            icon: Icons.email,
            title: 'Email',
            subtitle: 'support@saferide.com',
            onTap: () => _launchEmail('support@saferide.com'),
          ),
          _buildContactItem(
            icon: Icons.phone,
            title: 'Phone',
            subtitle: '+234 800 123 4567',
            onTap: () => _launchPhone('+2348001234567'),
          ),
          _buildContactItem(
            icon: Icons.access_time,
            title: 'Support Hours',
            subtitle: '24/7 Available',
            onTap: null,
          ),
          _buildContactItem(
            icon: Icons.location_on,
            title: 'Address',
            subtitle: 'Lagos, Nigeria',
            onTap: null,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.deepPurple.shade600,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      onTap: onTap,
      trailing: onTap != null
          ? Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            )
          : null,
    );
  }

  void _startLiveChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Live Chat'),
        content: const Text('Live chat feature is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _sendEmail() {
    _launchEmail('support@saferide.com');
  }

  void _callSupport() {
    _launchPhone('+2348001234567');
  }

  void _reportIssue() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Issue'),
        content: const Text('Please describe the issue you\'re experiencing:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _launchEmail('support@saferide.com', subject: 'Issue Report');
            },
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail(String email, {String? subject}) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Email: $email${subject != null ? ' - $subject' : ''}')),
    );
  }

  Future<void> _launchPhone(String phone) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Call: $phone')),
    );
  }
}

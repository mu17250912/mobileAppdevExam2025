import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumFeaturesScreen extends StatefulWidget {
  final String userEmail;
  final String userRole;
  
  const PremiumFeaturesScreen({
    Key? key, 
    required this.userEmail, 
    required this.userRole
  }) : super(key: key);

  @override
  State<PremiumFeaturesScreen> createState() => _PremiumFeaturesScreenState();
}

class _PremiumFeaturesScreenState extends State<PremiumFeaturesScreen> {
  String selectedPlan = 'monthly';

  final List<Map<String, dynamic>> subscriptionPlans = [
    {
      'name': 'Basic',
      'price': 'Free',
      'period': 'Forever',
      'features': [
        'Access to 5 courses per month',
        'Basic skill tracking',
        'Connect with 3 trainers',
        'Standard support',
      ],
      'isPopular': false,
      'isFree': true,
    },
    {
      'name': 'Pro',
      'price': '\$9.99',
      'period': 'per month',
      'features': [
        'Unlimited course access',
        'Advanced skill analytics',
        'Connect with unlimited trainers',
        'Priority support',
        'Download courses offline',
        'Advanced search filters',
        'Course completion certificates',
      ],
      'isPopular': true,
      'isFree': false,
    },
    {
      'name': 'Premium',
      'price': '\$19.99',
      'period': 'per month',
      'features': [
        'All Pro features',
        '1-on-1 mentoring sessions',
        'Custom learning paths',
        'Exclusive premium courses',
        'Advanced progress tracking',
        'Priority course recommendations',
        'Dedicated success manager',
      ],
      'isPopular': false,
      'isFree': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Premium Features',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: widget.userRole == 'trainer' ? Colors.green : Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildFeatureComparison(),
            const SizedBox(height: 24),
            _buildSubscriptionPlans(),
            const SizedBox(height: 24),
            _buildTestimonials(),
            const SizedBox(height: 24),
            _buildFAQ(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.star,
              size: 64,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            Text(
              'Unlock Your Full Potential',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Upgrade to Premium and accelerate your learning journey with exclusive features and personalized support.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureComparison() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feature Comparison',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureRow('Course Access', '5/month', 'Unlimited', 'Unlimited'),
            _buildFeatureRow('Trainer Connections', '3', 'Unlimited', 'Unlimited'),
            _buildFeatureRow('Offline Downloads', '❌', '✅', '✅'),
            _buildFeatureRow('1-on-1 Mentoring', '❌', '❌', '✅'),
            _buildFeatureRow('Priority Support', '❌', '✅', '✅'),
            _buildFeatureRow('Certificates', '❌', '✅', '✅'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String feature, String basic, String pro, String premium) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              basic,
              style: GoogleFonts.poppins(
                color: basic == '❌' ? Colors.red : Colors.green,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              pro,
              style: GoogleFonts.poppins(
                color: pro == '❌' ? Colors.red : Colors.green,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              premium,
              style: GoogleFonts.poppins(
                color: premium == '❌' ? Colors.red : Colors.green,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionPlans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Plan',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...subscriptionPlans.map((plan) => _buildPlanCard(plan)),
      ],
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final isPopular = plan['isPopular'] as bool;
    final isFree = plan['isFree'] as bool;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isPopular ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPopular 
            ? BorderSide(color: Colors.amber, width: 2)
            : BorderSide.none,
      ),
      child: Stack(
        children: [
          if (isPopular)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'MOST POPULAR',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          plan['price'],
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isFree ? Colors.green : Colors.blue,
                          ),
                        ),
                        Text(
                          plan['period'],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...(plan['features'] as List<String>).map((feature) => 
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleSubscription(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFree 
                          ? Colors.green 
                          : (widget.userRole == 'trainer' ? Colors.green : Colors.blue),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isFree ? 'Get Started' : 'Subscribe Now',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonials() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What Our Users Say',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTestimonial(
              'Sarah Johnson',
              'Learner',
              'The premium features helped me accelerate my learning. The 1-on-1 mentoring sessions were game-changing!',
              5,
            ),
            const SizedBox(height: 12),
            _buildTestimonial(
              'Mike Chen',
              'Trainer',
              'Premium subscribers are more engaged and complete more courses. It\'s a win-win for everyone!',
              5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestimonial(String name, String role, String comment, int rating) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: Text(
                  name[0],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      role,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) => 
                  Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment,
            style: GoogleFonts.poppins(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQ() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              'Can I cancel my subscription anytime?',
              'Yes, you can cancel your subscription at any time. You\'ll continue to have access to premium features until the end of your billing period.',
            ),
            _buildFAQItem(
              'Do you offer refunds?',
              'We offer a 30-day money-back guarantee. If you\'re not satisfied with our premium features, contact our support team.',
            ),
            _buildFAQItem(
              'Can I switch between plans?',
              'Yes, you can upgrade or downgrade your plan at any time. Changes will be reflected in your next billing cycle.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            answer,
            style: GoogleFonts.poppins(),
          ),
        ),
      ],
    );
  }

  void _handleSubscription(Map<String, dynamic> plan) {
    if (plan['isFree']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Welcome to SkillsLinks! Start exploring our free features.')),
      );
      Navigator.pop(context);
    } else {
      _showSimulatedPaymentDialog(context);
    }
  }

  void _showSimulatedPaymentDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Simulated Payment'),
          content: Text('This is a simulated payment dialog. No real transaction will occur.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Payment Successful'),
                    content: Text('You have successfully upgraded to premium (simulation).'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              child: Text('Simulate Payment'),
            ),
          ],
        );
      },
    );
  }
} 
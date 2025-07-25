import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/currency_service.dart';
import 'auth_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _amountController = TextEditingController(text: '100');
  String _fromCurrency = 'USD';
  String _toCurrency = 'RWF';
  double _convertedAmount = 0.0;
  bool _isConverting = false;
  bool _isProUnlocked = false;
  int _convertCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _convertCurrency();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _convertCurrency() async {
    if (_amountController.text.isEmpty) return;

    setState(() => _isConverting = true);

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final currencyService = Provider.of<CurrencyService>(context, listen: false);
    
    final converted = await currencyService.convertCurrency(
      fromCurrency: _fromCurrency,
      toCurrency: _toCurrency,
      amount: amount,
    );

    setState(() {
      _convertedAmount = converted;
      _isConverting = false;
      _convertCount++;
      // Do NOT unlock Pro automatically after 3 conversions
    });

    // Save conversion to Firebase
    if (converted > 0) {
      Provider.of<AuthService>(context, listen: false).saveConversion(
        fromCurrency: _fromCurrency,
        toCurrency: _toCurrency,
        amount: amount,
        convertedAmount: converted,
        rate: currencyService.lastRate,
      );
    }
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    _convertCurrency();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Premium Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4D9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFC107), width: 1.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.star, color: Color(0xFFFFC107), size: 28),
                                SizedBox(width: 8),
                                Text(
                                  'Upgrade to Premium',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isProUnlocked
                                  ? 'You have unlocked all Pro features!'
                                  : 'Unlock Pro features for the best experience.',
                              style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isProUnlocked ? Colors.green : const Color(0xFFFFC107),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isProUnlocked
                            ? null
                            : () async {
                                if (_convertCount < 3) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Convert 3 times to unlock or upgrade!'), backgroundColor: Colors.orange),
                                  );
                                  return;
                                }
                                final unlock = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Unlock Pro Features'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text('Unlock these Pro features:'),
                                        SizedBox(height: 10),
                                        Text('• No ads'),
                                        Text('• Unlimited conversions'),
                                        Text('• Priority support'),
                                        Text('• Early access to new features'),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.of(ctx).pop(true),
                                        child: const Text('Go Premium'),
                                      ),
                                    ],
                                  ),
                                );
                                if (unlock == true) {
                                  setState(() {
                                    _isProUnlocked = true;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Pro features unlocked!'), backgroundColor: Colors.green),
                                  );
                                }
                              },
                        child: Text(_isProUnlocked
                            ? 'Unlocked'
                            : (_convertCount >= 3 ? 'Upgrade' : 'Unlock')),
                      ),
                    ],
                  ),
                ),
              ),
              // App Header (start here, status bar removed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Currency Converter',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                                );
                              },
                              icon: const Icon(Icons.settings, color: Color(0xFF667eea)),
                              tooltip: 'Settings',
                            ),
                            IconButton(
                              onPressed: () async {
                                await Provider.of<AuthService>(context, listen: false).signOut();
                                if (mounted) {
                                  context.go('/login');
                                }
                              },
                              icon: const Icon(Icons.logout, color: Color(0xFF667eea)),
                              tooltip: 'Logout',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Convert any currency instantly',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Converter Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 25),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    // Amount Input
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Amount',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFf8f9fa),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFe1e5e9), width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFe1e5e9), width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
                            ),
                            contentPadding: const EdgeInsets.all(18),
                          ),
                          onChanged: (value) => _convertCurrency(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    // Currency Selection
                    Row(
                      children: [
                        Expanded(
                          child: _buildCurrencyDropdown(
                            value: _fromCurrency,
                            onChanged: (value) {
                              setState(() => _fromCurrency = value!);
                              _convertCurrency();
                            },
                          ),
                        ),
                        const SizedBox(width: 15),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF667eea),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF667eea).withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _swapCurrencies,
                              borderRadius: BorderRadius.circular(25),
                              child: const Center(
                                child: Icon(
                                  Icons.swap_horiz,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildCurrencyDropdown(
                            value: _toCurrency,
                            onChanged: (value) {
                              setState(() => _toCurrency = value!);
                              _convertCurrency();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    // Convert Button
                    Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667eea).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _convertCurrency,
                          borderRadius: BorderRadius.circular(12),
                          child: Center(
                            child: _isConverting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Convert Currency',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Result Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 25),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    const Text(
                      'Converted Amount',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      NumberFormat('#,##0.00').format(_convertedAmount),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _getCurrencyName(_toCurrency),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '1 ${_fromCurrency} = ${NumberFormat('#,##0.00').format(Provider.of<CurrencyService>(context, listen: false).lastRate)} ${_toCurrency}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Last updated: Just now',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // View History Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    icon: const Icon(Icons.history),
                    label: const Text('View History'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const HistoryScreen()),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Move Pro Features section to the bottom
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pro Features',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                    ),
                    const SizedBox(height: 10),
                    _buildProFeature('No ads', _isProUnlocked),
                    _buildProFeature('Unlimited conversions', _isProUnlocked),
                    _buildProFeature('Priority support', _isProUnlocked),
                    _buildProFeature('Early access to new features', _isProUnlocked),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyDropdown({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    final currencyService = Provider.of<CurrencyService>(context);
    final currencies = currencyService.getCurrencyList();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFe1e5e9), width: 2),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          items: currencies.map((currency) {
            return DropdownMenuItem<String>(
              value: currency.code,
              child: Row(
                children: [
                  Text(currency.flag, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currency.code,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getCurrencyName(String code) {
    final currencyService = Provider.of<CurrencyService>(context, listen: false);
    final currency = currencyService.getCurrency(code);
    return currency?.name ?? code;
  }

  Widget _buildProFeature(String feature, bool unlocked) {
    return Row(
      children: [
        Icon(
          unlocked ? Icons.lock_open : Icons.lock,
          color: unlocked ? Colors.green : Colors.grey,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          feature,
          style: TextStyle(
            fontSize: 14,
            color: unlocked ? Colors.green : Color(0xFF333333),
            fontWeight: unlocked ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
} 
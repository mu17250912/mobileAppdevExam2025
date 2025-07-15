import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Currency {
  final String code;
  final String name;
  final String flag;
  final double rate;

  Currency({
    required this.code,
    required this.name,
    required this.flag,
    required this.rate,
  });
}

class CurrencyService extends ChangeNotifier {
  Map<String, Currency> _currencies = {};
  bool _isLoading = false;
  String? _error;
  double _lastRate = 0.0;

  Map<String, Currency> get currencies => _currencies;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get lastRate => _lastRate;

  // Initialize with some popular currencies
  CurrencyService() {
    _initializeCurrencies();
  }

  void _initializeCurrencies() {
    _currencies = {
      'USD': Currency(code: 'USD', name: 'US Dollar', flag: '🇺🇸', rate: 1.0),
      'EUR': Currency(code: 'EUR', name: 'Euro', flag: '🇪🇺', rate: 0.85),
      'RWF': Currency(code: 'RWF', name: 'Rwandan Franc', flag: '🇷🇼', rate: 1300.0),
      'KES': Currency(code: 'KES', name: 'Kenyan Shilling', flag: '🇰🇪', rate: 150.0),
      'GBP': Currency(code: 'GBP', name: 'British Pound', flag: '🇬🇧', rate: 0.73),
      'JPY': Currency(code: 'JPY', name: 'Japanese Yen', flag: '🇯🇵', rate: 110.0),
      'CAD': Currency(code: 'CAD', name: 'Canadian Dollar', flag: '🇨🇦', rate: 1.25),
      'AUD': Currency(code: 'AUD', name: 'Australian Dollar', flag: '🇦🇺', rate: 1.35),
      'CHF': Currency(code: 'CHF', name: 'Swiss Franc', flag: '🇨🇭', rate: 0.92),
      'CNY': Currency(code: 'CNY', name: 'Chinese Yuan', flag: '🇨🇳', rate: 6.45),
    };
  }

  Future<void> fetchExchangeRates() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Using a free currency API (you can replace with your preferred API)
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;

        // Update rates for currencies we support
        for (String code in _currencies.keys) {
          if (rates.containsKey(code)) {
            _currencies[code] = Currency(
              code: code,
              name: _currencies[code]!.name,
              flag: _currencies[code]!.flag,
              rate: rates[code].toDouble(),
            );
          }
        }
      } else {
        _error = 'Failed to fetch exchange rates';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<double> convertCurrency({
    required String fromCurrency,
    required String toCurrency,
    required double amount,
  }) async {
    await fetchExchangeRates(); // Always fetch latest rates before conversion

    if (!_currencies.containsKey(fromCurrency) || 
        !_currencies.containsKey(toCurrency)) {
      return 0.0;
    }

    final fromRate = _currencies[fromCurrency]!.rate;
    final toRate = _currencies[toCurrency]!.rate;
    
    // Convert to USD first, then to target currency
    final usdAmount = amount / fromRate;
    final convertedAmount = usdAmount * toRate;
    
    _lastRate = toRate / fromRate;
    return convertedAmount;
  }

  List<Currency> getCurrencyList() {
    return _currencies.values.toList();
  }

  Currency? getCurrency(String code) {
    return _currencies[code];
  }

  void swapCurrencies(String fromCurrency, String toCurrency) {
    // This method can be used to swap currencies in the UI
    notifyListeners();
  }
} 
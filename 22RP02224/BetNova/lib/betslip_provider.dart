import 'package:flutter/material.dart';

class BetSelection {
  final String matchId;
  final String matchTitle;
  final String market;
  final String oddKey;
  final double oddValue;

  BetSelection({
    required this.matchId,
    required this.matchTitle,
    required this.market,
    required this.oddKey,
    required this.oddValue,
  });
}

class BetSlipProvider extends ChangeNotifier {
  final List<BetSelection> _selections = [];

  List<BetSelection> get selections => List.unmodifiable(_selections);

  void addOrUpdateSelection(BetSelection selection) {
    // Remove all previous selections for this match (regardless of market or oddKey)
    _selections.removeWhere((s) => s.matchId == selection.matchId);
    _selections.add(selection);
    notifyListeners();
  }

  void removeSelection(String matchId) {
    _selections.removeWhere((s) => s.matchId == matchId);
    notifyListeners();
  }

  void clear() {
    _selections.clear();
    notifyListeners();
  }

  double get cumulativeOdds {
    if (_selections.isEmpty) return 0.0;
    return _selections.fold(1.0, (prev, s) => prev * s.oddValue);
  }
} 
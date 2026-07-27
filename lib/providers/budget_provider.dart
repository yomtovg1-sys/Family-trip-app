import 'package:flutter/material.dart';
import '../models/budget_entry.dart';

class BudgetProvider extends ChangeNotifier {
  double _totalBudget = 4000;

  final List<BudgetEntry> _entries = [
    BudgetEntry(
      id: 'b1',
      description: 'Round-trip flights',
      amount: 1450,
      category: BudgetCategory.flights,
      paidBy: 'Mom',
      date: DateTime.now().subtract(const Duration(days: 10)),
    ),
    BudgetEntry(
      id: 'b2',
      description: 'Cabin rental (7 nights)',
      amount: 1200,
      category: BudgetCategory.lodging,
      paidBy: 'Dad',
      date: DateTime.now().subtract(const Duration(days: 8)),
    ),
    BudgetEntry(
      id: 'b3',
      description: 'Rental car',
      amount: 380,
      category: BudgetCategory.transport,
      paidBy: 'Dad',
      date: DateTime.now().subtract(const Duration(days: 5)),
    ),
    BudgetEntry(
      id: 'b4',
      description: 'Kayak rental',
      amount: 90,
      category: BudgetCategory.activities,
      paidBy: 'Mom',
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  List<BudgetEntry> get entries => List.unmodifiable(_entries);

  double get totalBudget => _totalBudget;

  double get totalSpent => _entries.fold(0, (sum, e) => sum + e.amount);

  double get remaining => _totalBudget - totalSpent;

  double get progress => _totalBudget <= 0 ? 0 : (totalSpent / _totalBudget).clamp(0, 1);

  Map<BudgetCategory, double> get spendByCategory {
    final map = <BudgetCategory, double>{};
    for (final e in _entries) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  void addEntry(BudgetEntry entry) {
    _entries.add(entry);
    notifyListeners();
  }

  void setTotalBudget(double amount) {
    _totalBudget = amount;
    notifyListeners();
  }
}

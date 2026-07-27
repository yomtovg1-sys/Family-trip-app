enum BudgetCategory { flights, lodging, food, activities, transport, shopping, other }

extension BudgetCategoryX on BudgetCategory {
  String get label {
    switch (this) {
      case BudgetCategory.flights:
        return 'Flights';
      case BudgetCategory.lodging:
        return 'Lodging';
      case BudgetCategory.food:
        return 'Food';
      case BudgetCategory.activities:
        return 'Activities';
      case BudgetCategory.transport:
        return 'Transport';
      case BudgetCategory.shopping:
        return 'Shopping';
      case BudgetCategory.other:
        return 'Other';
    }
  }
}

class BudgetEntry {
  final String id;
  final String description;
  final double amount;
  final BudgetCategory category;
  final String paidBy;
  final DateTime date;

  const BudgetEntry({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.paidBy,
    required this.date,
  });
}

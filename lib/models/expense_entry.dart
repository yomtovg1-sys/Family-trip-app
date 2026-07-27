import 'package:flutter/material.dart';

enum ExpenseCategory { food, hotels, transportation, shopping, attractions }

extension ExpenseCategoryX on ExpenseCategory {
  String get label {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.hotels:
        return 'Hotels';
      case ExpenseCategory.transportation:
        return 'Transportation';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.attractions:
        return 'Attractions';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.hotels:
        return Icons.hotel_rounded;
      case ExpenseCategory.transportation:
        return Icons.directions_car_rounded;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_rounded;
      case ExpenseCategory.attractions:
        return Icons.attractions_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return const Color(0xFFFF8A65);
      case ExpenseCategory.hotels:
        return const Color(0xFF7986CB);
      case ExpenseCategory.transportation:
        return const Color(0xFF4FC3F7);
      case ExpenseCategory.shopping:
        return const Color(0xFFBA68C8);
      case ExpenseCategory.attractions:
        return const Color(0xFFFFC94D);
    }
  }
}

class ExpenseEntry {
  final String id;
  final String description;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;

  const ExpenseEntry({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
  });
}

import 'package:flutter/material.dart';
import 'travel_document.dart';

enum ExpenseCategory {
  flights,
  hotel,
  transportation,
  food,
  attractions,
  shopping,
  coffee,
  grocery,
  other,
}

extension ExpenseCategoryX on ExpenseCategory {
  String get emoji {
    switch (this) {
      case ExpenseCategory.flights:
        return '✈️';
      case ExpenseCategory.hotel:
        return '🏨';
      case ExpenseCategory.transportation:
        return '🚗';
      case ExpenseCategory.food:
        return '🍣';
      case ExpenseCategory.attractions:
        return '🎟️';
      case ExpenseCategory.shopping:
        return '🛍️';
      case ExpenseCategory.coffee:
        return '☕';
      case ExpenseCategory.grocery:
        return '🛒';
      case ExpenseCategory.other:
        return '📦';
    }
  }

  String get label {
    switch (this) {
      case ExpenseCategory.flights:
        return 'Flights';
      case ExpenseCategory.hotel:
        return 'Hotel';
      case ExpenseCategory.transportation:
        return 'Transportation';
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.attractions:
        return 'Attractions';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.coffee:
        return 'Coffee';
      case ExpenseCategory.grocery:
        return 'Grocery';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.flights:
        return const Color(0xFF4FC3F7);
      case ExpenseCategory.hotel:
        return const Color(0xFF7986CB);
      case ExpenseCategory.transportation:
        return const Color(0xFF64B5F6);
      case ExpenseCategory.food:
        return const Color(0xFFFF8A65);
      case ExpenseCategory.attractions:
        return const Color(0xFFFFC94D);
      case ExpenseCategory.shopping:
        return const Color(0xFFBA68C8);
      case ExpenseCategory.coffee:
        return const Color(0xFF8D6E63);
      case ExpenseCategory.grocery:
        return const Color(0xFF81C784);
      case ExpenseCategory.other:
        return const Color(0xFF90A4AE);
    }
  }
}

/// One logged expense. [merchant] and the time-of-day component of [date]
/// are typically only populated when the expense came from a scanned
/// receipt (see [ExpenseExtractor]) — a manually entered expense just has an
/// amount, currency, category, and optional notes.
class ExpenseEntry {
  final String id;
  final double amount;
  final String currency;
  final ExpenseCategory category;
  final DateTime date;
  final String? merchant;
  final String? notes;
  final double? vatAmount;
  final String? paymentMethod;
  final TravelDocument? receipt;

  const ExpenseEntry({
    required this.id,
    required this.amount,
    required this.currency,
    required this.category,
    required this.date,
    this.merchant,
    this.notes,
    this.vatAmount,
    this.paymentMethod,
    this.receipt,
  });

  /// The best short label to show in a list: the merchant name if known,
  /// otherwise the notes, otherwise just the category.
  String get title {
    if (merchant != null && merchant!.trim().isNotEmpty) return merchant!.trim();
    if (notes != null && notes!.trim().isNotEmpty) return notes!.trim();
    return category.label;
  }
}

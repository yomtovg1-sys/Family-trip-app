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

  IconData get icon {
    switch (this) {
      case ExpenseCategory.flights:
        return Icons.flight_rounded;
      case ExpenseCategory.hotel:
        return Icons.hotel_rounded;
      case ExpenseCategory.transportation:
        return Icons.directions_car_rounded;
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.attractions:
        return Icons.confirmation_number_rounded;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_rounded;
      case ExpenseCategory.coffee:
        return Icons.coffee_rounded;
      case ExpenseCategory.grocery:
        return Icons.shopping_cart_rounded;
      case ExpenseCategory.other:
        return Icons.inventory_2_rounded;
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
        return const Color(0xFF2F80ED);
      case ExpenseCategory.hotel:
        return const Color(0xFF9B6BFF);
      case ExpenseCategory.transportation:
        return const Color(0xFF1AA5A0);
      case ExpenseCategory.food:
        return const Color(0xFFFF7043);
      case ExpenseCategory.attractions:
        return const Color(0xFFFFB300);
      case ExpenseCategory.shopping:
        return const Color(0xFFE0559C);
      case ExpenseCategory.coffee:
        return const Color(0xFF8D6E63);
      case ExpenseCategory.grocery:
        return const Color(0xFF66BB6A);
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'currency': currency,
        'category': category.name,
        'date': date.toIso8601String(),
        'merchant': merchant,
        'notes': notes,
        'vatAmount': vatAmount,
        'paymentMethod': paymentMethod,
        'receipt': receipt?.toJson(),
      };

  factory ExpenseEntry.fromJson(Map<String, dynamic> json) {
    return ExpenseEntry(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      category: ExpenseCategory.values.byName(json['category'] as String),
      date: DateTime.parse(json['date'] as String),
      merchant: json['merchant'] as String?,
      notes: json['notes'] as String?,
      vatAmount: (json['vatAmount'] as num?)?.toDouble(),
      paymentMethod: json['paymentMethod'] as String?,
      receipt:
          json['receipt'] != null ? TravelDocument.fromJson(json['receipt'] as Map<String, dynamic>) : null,
    );
  }
}

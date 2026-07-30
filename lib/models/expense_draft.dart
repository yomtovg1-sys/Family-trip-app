import 'package:flutter/material.dart';
import 'expense_entry.dart';

/// Fields recognized from a scanned receipt. Produced by an
/// [ExpenseExtractor] and used to pre-fill the "Add Expense" sheet so the
/// traveler only has to confirm/correct fields instead of typing everything
/// from scratch.
class ExpenseDraft {
  final String? merchant;
  final double? amount;
  final String? currency;
  final ExpenseCategory? suggestedCategory;
  final DateTime? date;
  final TimeOfDay? time;
  final double? vatAmount;
  final String? paymentMethod;

  const ExpenseDraft({
    this.merchant,
    this.amount,
    this.currency,
    this.suggestedCategory,
    this.date,
    this.time,
    this.vatAmount,
    this.paymentMethod,
  });

  bool get isEmpty =>
      merchant == null &&
      amount == null &&
      currency == null &&
      suggestedCategory == null &&
      date == null &&
      time == null &&
      vatAmount == null &&
      paymentMethod == null;
}

import 'package:flutter/material.dart';
import '../models/expense_draft.dart';
import '../models/expense_entry.dart';
import '../models/travel_document.dart';

/// Architecture seam for AI-assisted receipt reading. A future
/// implementation would send [receipt] (a photo or PDF of a receipt)
/// through an OCR/LLM pipeline and recognize:
///  - merchant name
///  - total amount
///  - currency
///  - purchase date and time
///  - VAT, when available
///  - the most appropriate expense category
///  - payment method, when available
///
/// ...returning them as an [ExpenseDraft] that pre-fills the "Add Expense"
/// sheet's review step, so the traveler only has to confirm — not retype —
/// the receipt.
///
/// No real extraction is implemented yet; [MockExpenseExtractor] is the
/// current placeholder implementation so the rest of the app (receipt
/// attachment in the Add Expense sheet) can already be wired against this
/// interface.
abstract class ExpenseExtractor {
  Future<ExpenseDraft> extract(TravelDocument receipt, {String? tripCurrency});
}

class MockExpenseExtractor implements ExpenseExtractor {
  const MockExpenseExtractor();

  @override
  Future<ExpenseDraft> extract(TravelDocument receipt, {String? tripCurrency}) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final now = DateTime.now();
    return ExpenseDraft(
      merchant: '7-Eleven',
      amount: 2430,
      currency: tripCurrency ?? 'JPY',
      suggestedCategory: ExpenseCategory.food,
      date: DateTime(now.year, now.month, now.day),
      time: TimeOfDay(hour: now.hour, minute: now.minute),
      vatAmount: null,
      paymentMethod: null,
    );
  }
}

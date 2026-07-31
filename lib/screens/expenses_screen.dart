import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense_entry.dart';
import '../providers/trip_provider.dart';
import '../utils/currency.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_section.dart';
import '../widgets/emoji_text.dart';
import '../widgets/expenses/add_expense_sheet.dart';
import '../widgets/expenses_card.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<TripProvider>().current;
    final dateFormat = DateFormat('MMM d');
    final entries = dashboard.expenses.reversed.toList();
    final currency = dashboard.trip.currency;

    return Scaffold(
      appBar: AppBar(title: const Text('Travel Expenses')),
      drawer: const AppDrawer(currentRoute: AppSection.expensesRoute),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddExpenseSheet(
          context,
          tripCurrency: currency,
          onSave: (expense) =>
              context.read<TripProvider>().addExpense(dashboard.trip.id, expense),
        ),
        child: const Icon(Icons.add_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          ExpensesCard(
            todayTotal: dashboard.todayExpenses,
            tripTotal: dashboard.totalExpenses,
            byCategory: dashboard.expensesByCategory,
            currency: currency,
          ),
          const SizedBox(height: 20),
          Text('All Expenses', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No expenses logged for this trip yet. Tap + to add your first one.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            for (final entry in entries)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: entry.category.color.withValues(alpha: 0.15),
                    child: EmojiText(entry.category.emoji, style: const TextStyle(fontSize: 18)),
                  ),
                  title: Text(entry.title),
                  subtitle: Text('${entry.category.label} · ${dateFormat.format(entry.date)}'),
                  trailing: Text(
                    formatMoney(entry.amount, entry.currency),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

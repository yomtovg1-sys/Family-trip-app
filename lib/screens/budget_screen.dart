import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/budget_entry.dart';
import '../providers/budget_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_section.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final budget = context.watch<BudgetProvider>();
    final currency = NumberFormat.simpleCurrency();
    final theme = Theme.of(context);
    final overBudget = budget.remaining < 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Budget Tracker')),
      drawer: const AppDrawer(currentRoute: AppSection.budgetRoute),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _BudgetStat(label: 'Budget', value: currency.format(budget.totalBudget)),
                      _BudgetStat(label: 'Spent', value: currency.format(budget.totalSpent)),
                      _BudgetStat(
                        label: overBudget ? 'Over by' : 'Remaining',
                        value: currency.format(budget.remaining.abs()),
                        color: overBudget ? theme.colorScheme.error : Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: budget.progress,
                      minHeight: 10,
                      color: overBudget ? theme.colorScheme.error : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Expenses', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final entry in budget.entries.reversed)
            Card(
              child: ListTile(
                title: Text(entry.description),
                subtitle: Text('${entry.category.label} · Paid by ${entry.paidBy}'),
                trailing: Text(
                  currency.format(entry.amount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BudgetStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _BudgetStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

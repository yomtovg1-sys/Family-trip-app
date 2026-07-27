import 'dart:math';
import 'package:flutter/material.dart';
import '../models/expense_entry.dart';

class ExpensesCard extends StatelessWidget {
  final double todayTotal;
  final double tripTotal;
  final Map<ExpenseCategory, double> byCategory;

  const ExpensesCard({
    super.key,
    required this.todayTotal,
    required this.tripTotal,
    required this.byCategory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedEntries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatColumn(label: "Today", amount: todayTotal),
              const SizedBox(width: 28),
              _StatColumn(label: 'Trip total', amount: tripTotal),
            ],
          ),
          const SizedBox(height: 20),
          if (sortedEntries.isEmpty)
            Text(
              'No expenses logged yet',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 104,
                  height: 104,
                  child: CustomPaint(
                    painter: _DonutPainter(byCategory, tripTotal),
                    child: Center(
                      child: Text(
                        '${sortedEntries.length}',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final entry in sortedEntries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: entry.key.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(entry.key.label, style: theme.textTheme.bodySmall),
                              ),
                              Text(
                                '\$${entry.value.toStringAsFixed(0)}',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final double amount;

  const _StatColumn({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(0)}',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final Map<ExpenseCategory, double> data;
  final double total;

  _DonutPainter(this.data, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(6, 6, size.width - 12, size.height - 12);
    if (total <= 0) {
      final paint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12;
      canvas.drawArc(rect, 0, 2 * pi, false, paint);
      return;
    }
    var startAngle = -pi / 2;
    for (final entry in data.entries) {
      final sweep = (entry.value / total) * 2 * pi;
      final paint = Paint()
        ..color = entry.key.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;
      final gap = data.length > 1 ? 0.045 : 0.0;
      canvas.drawArc(rect, startAngle + gap, max(sweep - gap * 2, 0.001), false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.total != total;
}

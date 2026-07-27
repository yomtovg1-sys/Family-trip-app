import 'package:flutter/material.dart';
import '../models/travel_alert.dart';

class AlertsBanner extends StatelessWidget {
  final List<TravelAlert> alerts;

  const AlertsBanner({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        for (final alert in alerts)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: alert.severity.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border(left: BorderSide(color: alert.severity.color, width: 4)),
            ),
            child: Row(
              children: [
                Icon(alert.icon, color: alert.severity.color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    alert.message,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

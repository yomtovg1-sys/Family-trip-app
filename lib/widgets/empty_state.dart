import 'package:flutter/material.dart';

/// The centered "nothing here yet" placeholder used across every screen
/// with a list that can be empty — an icon (or emoji), a short title, and
/// an explanatory subtitle, always in the same layout and spacing.
class EmptyState extends StatelessWidget {
  final Widget visual;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    required this.visual,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            visual,
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

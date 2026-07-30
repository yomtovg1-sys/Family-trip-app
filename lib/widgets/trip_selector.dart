import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/trip.dart';
import '../providers/trip_provider.dart';
import 'app_section.dart';

String tripChipLabel(Trip trip) =>
    '${trip.flagEmoji} ${trip.destination.split(',').last.trim()} ${trip.startDate.year}';

/// The chip on Home showing the active trip — tapping it opens Trip
/// Manager, the one place to switch between trips or create a new one.
class TripSelector extends StatelessWidget {
  const TripSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripProvider>().current.trip;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.of(context).pushNamed(AppSection.tripManagerRoute),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tripChipLabel(trip), style: theme.textTheme.titleSmall),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

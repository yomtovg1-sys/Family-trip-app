import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/journey_stop.dart';
import '../providers/trip_provider.dart';

class JourneyCard extends StatelessWidget {
  final TripDashboard dashboard;

  const JourneyCard({super.key, required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = dashboard.displayStop;
    final next = dashboard.nextStop;
    final currentIndex = dashboard.journeyStops.indexOf(current);

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
          _LocationBlock(
            label: dashboard.locationSectionLabel,
            location: current.location,
            dateRange: _formatRange(current),
            emphasized: true,
            color: theme.colorScheme.primary,
          ),
          if (next != null) ...[
            const SizedBox(height: 16),
            _LocationBlock(
              label: 'Next destination',
              location: next.location,
              dateRange: _formatRange(next),
              emphasized: false,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
          if (dashboard.trip.hasEnded) ...[
            const SizedBox(height: 4),
            Text(
              'You explored ${dashboard.journeyStops.length} places on this trip',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 20),
          _JourneyTimeline(stops: dashboard.journeyStops, currentIndex: currentIndex),
        ],
      ),
    );
  }

  String _formatRange(JourneyStop stop) {
    final format = DateFormat('d MMM');
    return '${format.format(stop.start)} – ${format.format(stop.end)}';
  }
}

class _LocationBlock extends StatelessWidget {
  final String label;
  final String location;
  final String dateRange;
  final bool emphasized;
  final Color color;

  const _LocationBlock({
    required this.label,
    required this.location,
    required this.dateRange,
    required this.emphasized,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            emphasized ? Icons.location_on_rounded : Icons.arrow_forward_rounded,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                location,
                style: emphasized ? theme.textTheme.titleLarge : theme.textTheme.titleSmall,
              ),
            ],
          ),
        ),
        Text(
          dateRange,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _JourneyTimeline extends StatelessWidget {
  final List<JourneyStop> stops;
  final int currentIndex;

  const _JourneyTimeline({required this.stops, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        for (var i = 0; i < stops.length; i++) ...[
          Column(
            children: [
              Container(
                width: i == currentIndex ? 14 : 9,
                height: i == currentIndex ? 14 : 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= currentIndex
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                stops[i].location,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: i == currentIndex
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: i == currentIndex ? FontWeight.w700 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          if (i != stops.length - 1)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  height: 2,
                  color: i < currentIndex
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

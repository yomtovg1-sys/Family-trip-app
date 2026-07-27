import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_section.dart';
import '../widgets/countdown_timer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripProvider>().trip;
    final dateFormat = DateFormat('MMM d');
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Family Trip Planner')),
      drawer: const AppDrawer(currentRoute: AppSection.homeRoute),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(trip.heroEmoji, style: const TextStyle(fontSize: 36)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            trip.destination,
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${dateFormat.format(trip.startDate)} - ${dateFormat.format(trip.endDate)} · ${trip.durationInDays} days',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                if (trip.hasEnded)
                  const Center(
                    child: Text(
                      'What a trip! 🎉',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  )
                else if (trip.hasStarted)
                  Center(
                    child: Text(
                      'You\'re on the trip! 🏕️',
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                  )
                else ...[
                  Text(
                    'Counting down to takeoff',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  CountdownTimer(target: trip.startDate),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Quick Access', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              for (final section in AppSection.quickAccess)
                _QuickAccessCard(
                  section: section,
                  onTap: () => Navigator.of(context).pushNamed(section.route),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final AppSection section;
  final VoidCallback onTap;

  const _QuickAccessCard({required this.section, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: section.color.withValues(alpha: 0.12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(section.icon, color: section.color, size: 32),
              const SizedBox(height: 10),
              Text(
                section.title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/trip.dart';
import '../providers/trip_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_section.dart';
import '../widgets/countdown_timer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripProvider>().trip;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Trip Planner'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const AppDrawer(currentRoute: AppSection.homeRoute),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _CountdownHeroCard(trip: trip),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
          ),
        ],
      ),
    );
  }
}

/// The big, warm, family-facing countdown hero. This is the first thing a
/// family member sees when opening the app: the trip photo as a backdrop
/// with a large, exciting countdown overlaid on top.
class _CountdownHeroCard extends StatelessWidget {
  final Trip trip;

  const _CountdownHeroCard({required this.trip});

  static const _gold = Color(0xFFFFC94D);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d');

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: SizedBox(
        height: 440,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/family_hero.jpg', fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000000),
                    Color(0x992E1608),
                    Color(0xE83E1204),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('👨‍👩‍👧‍👦', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        _eyebrow(),
                        style: const TextStyle(
                          color: _gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildHeadline(context),
                  const SizedBox(height: 18),
                  _buildBody(context),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${trip.destination} · ${dateFormat.format(trip.startDate)} - ${dateFormat.format(trip.endDate)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _eyebrow() {
    if (trip.hasEnded) return 'ADVENTURE COMPLETE';
    if (trip.hasStarted) return 'LIVING THE ADVENTURE';
    return 'FAMILY ADVENTURE AWAITS';
  }

  Widget _buildHeadline(BuildContext context) {
    if (trip.hasEnded) {
      return const Text(
        'What a trip! 🎉',
        style: TextStyle(
          color: Colors.white,
          fontSize: 34,
          fontWeight: FontWeight.w800,
          shadows: [Shadow(blurRadius: 10, color: Colors.black45)],
        ),
      );
    }
    if (trip.hasStarted) {
      final dayNumber = (DateTime.now().difference(trip.startDate).inDays + 1)
          .clamp(1, trip.durationInDays);
      return _BigStat(number: '$dayNumber', suffix: 'of ${trip.durationInDays} days');
    }
    final days = trip.timeUntilStart.isNegative ? 0 : trip.timeUntilStart.inDays;
    return _BigStat(number: '$days', suffix: days == 1 ? 'day to go!' : 'days to go!');
  }

  Widget _buildBody(BuildContext context) {
    if (trip.hasEnded) {
      return Row(
        children: [
          Expanded(
            child: Text(
              'Relive the memories from ${trip.destination}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70),
            ),
            onPressed: () => Navigator.of(context).pushNamed(AppSection.photosRoute),
            child: const Text('Photo Journal'),
          ),
        ],
      );
    }
    if (trip.hasStarted) {
      return Text(
        "We're making memories in ${trip.destination}! 🏕️",
        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
      );
    }
    return CountdownTimer(target: trip.startDate);
  }
}

class _BigStat extends StatelessWidget {
  final String number;
  final String suffix;

  const _BigStat({required this.number, required this.suffix});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          number,
          style: const TextStyle(
            color: _CountdownHeroCard._gold,
            fontSize: 72,
            fontWeight: FontWeight.w900,
            height: 1,
            shadows: [Shadow(blurRadius: 12, color: Colors.black54)],
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            suffix,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              shadows: [Shadow(blurRadius: 8, color: Colors.black45)],
            ),
          ),
        ),
      ],
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

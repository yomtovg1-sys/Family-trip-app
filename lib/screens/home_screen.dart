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

  static const double _heroHeight = 300;
  static const double _cardOverlap = 56;

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
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                height: _heroHeight,
                width: double.infinity,
                child: _HeroPhoto(trip: trip),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: -_cardOverlap,
                child: _TripStatusCard(trip: trip),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, _cardOverlap + 20, 16, 16),
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

class _HeroPhoto extends StatelessWidget {
  final Trip trip;

  const _HeroPhoto({required this.trip});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d');

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/family_hero.jpg', fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
                stops: [0.35, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 76,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(trip.heroEmoji, style: const TextStyle(fontSize: 30)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trip.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 8, color: Colors.black45)],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      trip.destination,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${dateFormat.format(trip.startDate)} - ${dateFormat.format(trip.endDate)} · ${trip.durationInDays} days',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TripStatusCard extends StatelessWidget {
  final Trip trip;

  const _TripStatusCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (trip.hasEnded) {
      return const _StatusHeadline(icon: Icons.emoji_events, text: 'What a trip! 🎉');
    }
    if (trip.hasStarted) {
      final dayNumber = (DateTime.now().difference(trip.startDate).inDays + 1)
          .clamp(1, trip.durationInDays);
      return Column(
        children: [
          const _StatusHeadline(icon: Icons.hiking, text: "You're on the trip!"),
          const SizedBox(height: 8),
          Text(
            'Day $dayNumber of ${trip.durationInDays}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      );
    }
    return Column(
      children: [
        const _StatusHeadline(icon: Icons.flight_takeoff, text: 'Counting down to takeoff'),
        const SizedBox(height: 16),
        CountdownTimer(target: trip.startDate),
      ],
    );
  }
}

class _StatusHeadline extends StatelessWidget {
  final IconData icon;
  final String text;

  const _StatusHeadline({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
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

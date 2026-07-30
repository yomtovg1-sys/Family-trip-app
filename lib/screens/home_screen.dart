import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/reservation.dart';
import '../models/trip.dart';
import '../providers/memories_provider.dart';
import '../providers/places_provider.dart';
import '../providers/reservations_provider.dart';
import '../providers/trip_provider.dart';
import '../screens/ai_assistant_screen.dart';
import '../services/trip_manager.dart';
import '../widgets/ai_assistant_card.dart';
import '../widgets/alerts_banner.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_section.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/expenses/add_expense_sheet.dart';
import '../widgets/expenses_card.dart';
import '../widgets/journey_card.dart';
import '../widgets/memories_preview.dart';
import '../widgets/section_header.dart';
import '../widgets/trip_selector.dart';
import '../widgets/weather_card.dart';
import '../models/expense_entry.dart';
import '../utils/currency.dart';
import '../utils/destination_covers.dart';
import '../widgets/destination_cover_image.dart';
import 'trip_manager_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hasTrips = context.watch<TripManager>().hasTrips;
    if (!hasTrips) return const _WelcomeScreen();

    final dashboard = context.watch<TripProvider>().current;
    final reservationsProvider = context.watch<ReservationsProvider>();
    final tripReservations = reservationsProvider.forTrip(dashboard.trip.id);
    final reservationsCount = tripReservations.length;
    final nextReservation = reservationsProvider.nextUpcoming(dashboard.trip.id);
    final walletDocumentCount = dashboard.documents.length +
        tripReservations.fold<int>(0, (sum, r) => sum + r.attachments.length);
    final photos = context.watch<MemoriesProvider>().forTrip(dashboard.trip.id);
    final placesCount = context.watch<PlacesProvider>().forTrip(dashboard.trip.id).length;
    final theme = Theme.of(context);

    var step = 0;
    Duration nextDelay() {
      final delay = Duration(milliseconds: 60 + step * 70);
      step++;
      return delay;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const AppDrawer(currentRoute: AppSection.homeRoute),
      body: ListView(
        key: const Key('homeScrollView'),
        padding: EdgeInsets.zero,
        children: [
          _Reveal(delay: nextDelay(), child: _CountdownHeroCard(dashboard: dashboard)),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Center(
              child: _Reveal(delay: nextDelay(), child: const TripSelector()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dashboard.alerts.isNotEmpty) ...[
                  _Reveal(delay: nextDelay(), child: AlertsBanner(alerts: dashboard.alerts)),
                  const SizedBox(height: 8),
                ],
                _Reveal(
                  delay: nextDelay(),
                  child: SectionHeader(title: dashboard.locationSectionLabel),
                ),
                const SizedBox(height: 12),
                _Reveal(delay: nextDelay(), child: JourneyCard(dashboard: dashboard)),
                const SizedBox(height: 28),
                if (dashboard.weather != null) ...[
                  _Reveal(delay: nextDelay(), child: const SectionHeader(title: 'Weather')),
                  const SizedBox(height: 12),
                  _Reveal(delay: nextDelay(), child: WeatherCard(weather: dashboard.weather!)),
                  const SizedBox(height: 28),
                ],
                _Reveal(
                  delay: nextDelay(),
                  child: SectionHeader(
                    title: 'Expenses',
                    subtitle: 'Tracked automatically, no budget cap',
                    trailing: IconButton.filledTonal(
                      icon: const Icon(Icons.add_rounded),
                      tooltip: 'Add expense',
                      onPressed: () => showAddExpenseSheet(
                        context,
                        tripCurrency: dashboard.trip.currency,
                        onSave: (expense) => context
                            .read<TripProvider>()
                            .addExpense(dashboard.trip.id, expense),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _Reveal(
                  delay: nextDelay(),
                  child: ExpensesCard(
                    todayTotal: dashboard.todayExpenses,
                    tripTotal: dashboard.totalExpenses,
                    byCategory: dashboard.expensesByCategory,
                    currency: dashboard.trip.currency,
                  ),
                ),
                if (dashboard.expenses.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _Reveal(
                    delay: nextDelay(),
                    child: _RecentExpenses(dashboard: dashboard),
                  ),
                ],
                const SizedBox(height: 28),
                _Reveal(
                  delay: nextDelay(),
                  child: SectionHeader(
                    title: 'Quick Access',
                    subtitle: 'Everything for ${dashboard.trip.name.split(' ').first}\'s trip',
                  ),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.15,
                  children: [
                    for (final item in _buildQuickAccessItems(
                      context: context,
                      dashboard: dashboard,
                      reservationsCount: reservationsCount,
                      nextReservation: nextReservation,
                      photoCount: photos.length,
                      walletDocumentCount: walletDocumentCount,
                      placesCount: placesCount,
                    ))
                      _Reveal(delay: nextDelay(), child: item),
                  ],
                ),
                const SizedBox(height: 28),
                _Reveal(
                  delay: nextDelay(),
                  child: AiAssistantCard(
                    onOpen: (prompt) => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AIAssistantScreen(initialPrompt: prompt),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _Reveal(delay: nextDelay(), child: const SectionHeader(title: 'Memories')),
                const SizedBox(height: 12),
                _Reveal(
                  delay: nextDelay(),
                  child: MemoriesPreview(
                    photos: photos,
                    onOpenJournal: () => Navigator.of(context).pushNamed(AppSection.photosRoute),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_QuickAccessCard> _buildQuickAccessItems({
    required BuildContext context,
    required TripDashboard dashboard,
    required int reservationsCount,
    required Reservation? nextReservation,
    required int photoCount,
    required int walletDocumentCount,
    required int placesCount,
  }) {
    String relativeDay(DateTime target) {
      final diff = target.difference(DateTime.now()).inDays;
      if (diff <= 0) return 'Today';
      if (diff == 1) return 'Tomorrow';
      return 'In $diff days';
    }

    void go(String route) => Navigator.of(context).pushNamed(route);

    return [
      _QuickAccessCard(
        title: 'Map',
        subtitle: '${dashboard.journeyStops.length} stops mapped',
        icon: Icons.map_rounded,
        color: const Color(0xFF2F9E44),
        onTap: () => go(AppSection.mapRoute),
      ),
      _QuickAccessCard(
        title: 'Places',
        subtitle: placesCount == 0 ? 'Discover nearby spots' : '$placesCount saved spots',
        icon: Icons.travel_explore_rounded,
        color: const Color(0xFFE8590C),
        onTap: () => go(AppSection.placesRoute),
      ),
      _QuickAccessCard(
        title: 'Expenses',
        subtitle: '${formatMoney(dashboard.totalExpenses, dashboard.trip.currency)} spent',
        icon: Icons.savings_rounded,
        color: const Color(0xFF2B8A8A),
        onTap: () => go(AppSection.expensesRoute),
      ),
      _QuickAccessCard(
        title: 'Memories',
        subtitle: '$photoCount photos',
        icon: Icons.photo_library_rounded,
        color: const Color(0xFFD6336C),
        onTap: () => go(AppSection.photosRoute),
      ),
      _QuickAccessCard(
        title: 'Reservations',
        subtitle: nextReservation != null
            ? '${nextReservation.category.emoji} ${nextReservation.category.singularLabel} · ${relativeDay(nextReservation.dateTime)}'
            : reservationsCount == 0
                ? 'No bookings yet'
                : '$reservationsCount saved',
        icon: Icons.confirmation_number_rounded,
        color: const Color(0xFF6741D9),
        onTap: () => go(AppSection.reservationsRoute),
      ),
      _QuickAccessCard(
        title: 'Travel Wallet',
        subtitle: walletDocumentCount == 0
            ? 'No documents yet'
            : '$walletDocumentCount documents',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF1F7A5C),
        onTap: () => go(AppSection.travelWalletRoute),
      ),
      _QuickAccessCard(
        title: 'AI Assistant',
        subtitle: 'Ask me anything',
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFF6C63FF),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AIAssistantScreen())),
      ),
      _QuickAccessCard(
        title: 'Sync & Backup',
        subtitle: 'Your data, safely saved',
        icon: Icons.cloud_done_rounded,
        color: const Color(0xFF1971C2),
        onTap: () => go(AppSection.syncBackupRoute),
      ),
      _QuickAccessCard(
        title: 'Personal Vault',
        subtitle: 'Passports, licenses & more',
        icon: Icons.shield_rounded,
        color: const Color(0xFF00838F),
        onTap: () => go(AppSection.personalVaultRoute),
      ),
      _QuickAccessCard(
        title: 'Trip Manager',
        subtitle: 'All trips, one place',
        icon: Icons.dashboard_customize_rounded,
        color: const Color(0xFF5C6BC0),
        onTap: () => go(AppSection.tripManagerRoute),
      ),
    ];
  }
}

/// A short preview of the most recently logged expenses, shown right under
/// the Expenses summary card so the family can see spending activity at a
/// glance without leaving Home.
class _RecentExpenses extends StatelessWidget {
  final TripDashboard dashboard;

  const _RecentExpenses({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recent = dashboard.expenses.reversed.take(3).toList();
    final dateFormat = DateFormat('MMM d');

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (final entry in recent)
              ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: entry.category.color.withValues(alpha: 0.15),
                  child: Text(entry.category.emoji, style: const TextStyle(fontSize: 15)),
                ),
                title: Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(dateFormat.format(entry.date)),
                trailing: Text(
                  formatMoney(entry.amount, entry.currency),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () => Navigator.of(context).pushNamed(AppSection.expensesRoute),
              ),
          ],
        ),
      ),
    );
  }
}

/// Fades and slides its child in shortly after being built. Used across the
/// Home screen so content arrives with a soft, premium entrance instead of
/// popping in instantly.
class _Reveal extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _Reveal({required this.child, this.delay = Duration.zero});

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      opacity: _visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        offset: _visible ? Offset.zero : const Offset(0, 0.05),
        child: widget.child,
      ),
    );
  }
}

/// The big, warm, family-facing countdown hero. This is the first thing a
/// family member sees when opening the app: the trip photo (or a gradient
/// fallback for trips without one yet) as a backdrop with a frosted-glass
/// countdown panel floating over it.
class _CountdownHeroCard extends StatelessWidget {
  final TripDashboard dashboard;

  const _CountdownHeroCard({required this.dashboard});

  static const _gold = Color(0xFFFFC94D);

  @override
  Widget build(BuildContext context) {
    final trip = dashboard.trip;
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: SizedBox(
        height: 490,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (trip.photoBytes != null)
              Image.memory(trip.photoBytes!, fit: BoxFit.cover)
            else if (destinationCoverFor(trip.country) != null)
              DestinationCoverImage(cover: destinationCoverFor(trip.country)!)
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer],
                  ),
                ),
                alignment: Alignment.center,
                child: Opacity(
                  opacity: 0.22,
                  child: Text(trip.heroEmoji, style: const TextStyle(fontSize: 160)),
                ),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0x1F000000)],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: _GlassPanel(trip: trip),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Trip trip;

  const _GlassPanel({required this.trip});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d');

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF3A1C0C).withValues(alpha: 0.55),
                const Color(0xFF241006).withValues(alpha: 0.42),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(trip.flagEmoji, style: const TextStyle(fontSize: 17)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _eyebrow(),
                      style: const TextStyle(
                        color: _CountdownHeroCard._gold,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                trip.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              _buildHeadline(context),
              const SizedBox(height: 18),
              _buildBody(context),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.white.withValues(alpha: 0.75), size: 15),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${trip.destination} · ${dateFormat.format(trip.startDate)} - ${dateFormat.format(trip.endDate)}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _eyebrow() {
    if (trip.hasEnded) return 'Adventure complete';
    if (trip.hasStarted) return 'Living the adventure';
    return 'Family adventure awaits';
  }

  Widget _buildHeadline(BuildContext context) {
    if (trip.hasEnded) {
      return const Text(
        'What a trip! 🎉',
        style: TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.w800,
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
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context).pushNamed(AppSection.photosRoute),
            child: const Text('Memories'),
          ),
        ],
      );
    }
    if (trip.hasStarted) {
      return Text(
        "We're making memories in ${trip.destination}! 🏕️",
        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
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
            color: Colors.white,
            fontSize: 56,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            suffix,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAccessCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickAccessCard> createState() => _QuickAccessCardState();
}

class _QuickAccessCardState extends State<_QuickAccessCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: widget.onTap,
        onHighlightChanged: (value) => setState(() => _pressed = value),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.color.withValues(alpha: 0.16),
                  widget.color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.color.withValues(alpha: 0.16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 21),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown instead of the dashboard on a fresh install, before any trip
/// exists. There's nowhere else to navigate yet — creating the first trip
/// is the only next step — so this replaces the whole screen rather than
/// layering onto the usual Scaffold/drawer.
class _WelcomeScreen extends StatelessWidget {
  const _WelcomeScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🌍', style: TextStyle(fontSize: 72)),
                const SizedBox(height: 20),
                Text(
                  'Plan your next family adventure',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Create your first trip to start tracking reservations, places, packing, and memories all in one spot.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreateTripScreen()),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create Your First Trip'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

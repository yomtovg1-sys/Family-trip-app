import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/reservation.dart';
import '../providers/reservations_provider.dart';
import '../providers/trip_provider.dart';
import '../services/document_extractor.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_section.dart';
import '../widgets/documents/add_document_sheet.dart';
import '../widgets/reservations/reservation_tile.dart';
import '../widgets/reservations/upcoming_reservation_card.dart';
import 'add_reservation_screen.dart';
import 'reservation_detail_screen.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  String _query = '';
  ReservationCategory? _category;
  ReservationStatus? _status;

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripProvider>().current.trip;
    final reservationsProvider = context.watch<ReservationsProvider>();
    final theme = Theme.of(context);

    final filtered = reservationsProvider.search(
      trip.id,
      query: _query,
      category: _category,
      status: _status,
    );
    final grouped = reservationsProvider.groupByDate(filtered);
    final sortedDates = grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: Text('Reservations · ${trip.name}')),
      drawer: const AppDrawer(currentRoute: AppSection.reservationsRoute),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddFlow(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          UpcomingReservationCard(
            reservation: reservationsProvider.nextUpcoming(trip.id),
            onTap: () {
              final next = reservationsProvider.nextUpcoming(trip.id);
              if (next != null) _openDetail(context, next.id);
            },
          ),
          const SizedBox(height: 24),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search hotel, airline, city, confirmation #…',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                for (final category in ReservationCategory.values.where(
                  (c) => c != ReservationCategory.other,
                ))
                  _FilterChip(
                    label: '${category.emoji} ${category.label}',
                    selected: _category == category,
                    onTap: () => setState(
                      () => _category = _category == category ? null : category,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'All statuses',
                  selected: _status == null,
                  onTap: () => setState(() => _status = null),
                  outlined: true,
                ),
                for (final status in ReservationStatus.values)
                  _FilterChip(
                    label: status.label,
                    selected: _status == status,
                    onTap: () => setState(
                      () => _status = _status == status ? null : status,
                    ),
                    color: status.color,
                    outlined: true,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (sortedDates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No reservations match your search.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else
            for (final date in sortedDates) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 6),
                child: Text(
                  DateFormat('d MMM').format(date),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              for (final reservation in grouped[date]!)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ReservationTile(
                    reservation: reservation,
                    onTap: () => _openDetail(context, reservation.id),
                  ),
                ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, String reservationId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReservationDetailScreen(reservationId: reservationId)),
    );
  }

  void _openAddFlow(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddReservationTypeSheet(),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  final bool outlined;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = color ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? activeColor.withValues(alpha: 0.14) : Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected
                ? activeColor.withValues(alpha: 0.5)
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected ? activeColor : theme.colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddReservationTypeSheet extends StatelessWidget {
  const _AddReservationTypeSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Add Reservation', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'What are you booking?',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final category in ReservationCategory.values)
                  _TypeTile(
                    category: category,
                    onTap: () {
                      Navigator.of(context).pop();
                      _openMethodSheet(context, category);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openMethodSheet(BuildContext context, ReservationCategory category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddReservationMethodSheet(category: category),
    );
  }
}

class _TypeTile extends StatelessWidget {
  final ReservationCategory category;
  final VoidCallback onTap;

  const _TypeTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: category.color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 96,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(category.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 8),
              Text(
                category.singularLabel,
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddReservationMethodSheet extends StatelessWidget {
  final ReservationCategory category;

  const _AddReservationMethodSheet({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${category.emoji} New ${category.singularLabel}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 18),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                child: Icon(Icons.edit_note_rounded, color: theme.colorScheme.primary),
              ),
              title: const Text('Enter details manually'),
              subtitle: const Text('Fill in the reservation form yourself'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddReservationScreen(category: category),
                  ),
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                child: Icon(Icons.upload_file_rounded, color: theme.colorScheme.primary),
              ),
              title: const Text('Upload a document first'),
              subtitle: const Text('Boarding pass, voucher, PDF, or screenshot'),
              onTap: () {
                Navigator.of(context).pop();
                _uploadFirst(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadFirst(BuildContext context) async {
    await showAddDocumentSheet(
      context,
      onPicked: (documents) async {
        if (documents.isEmpty) return;
        const extractor = MockDocumentExtractor();
        final draft = await extractor.extract(documents.first);
        if (!context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddReservationScreen(
              category: category,
              initialAttachment: documents.first,
              draft: draft,
            ),
          ),
        );
      },
    );
  }
}

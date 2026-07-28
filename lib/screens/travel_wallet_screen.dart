import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/reservation.dart';
import '../models/travel_document.dart';
import '../providers/reservations_provider.dart';
import '../providers/trip_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_section.dart';
import '../widgets/documents/add_document_sheet.dart';
import '../widgets/documents/document_card.dart';
import 'document_viewer_screen.dart';
import 'reservation_detail_screen.dart';

class TravelWalletScreen extends StatefulWidget {
  const TravelWalletScreen({super.key});

  @override
  State<TravelWalletScreen> createState() => _TravelWalletScreenState();
}

class _TravelWalletScreenState extends State<TravelWalletScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripProvider>().current.trip;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Wallet'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Trip Documents'),
            Tab(text: 'By Reservation'),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: AppSection.travelWalletRoute),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) => _tabController.index == 0
            ? FloatingActionButton(
                onPressed: () => _addTripDocument(context, trip.id),
                child: const Icon(Icons.add_rounded),
              )
            : const SizedBox.shrink(),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TripDocumentsTab(tripId: trip.id),
          _ByReservationTab(tripId: trip.id),
        ],
      ),
    );
  }

  Future<void> _addTripDocument(BuildContext context, String tripId) async {
    final category = await showModalBottomSheet<TripDocumentCategory>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CategoryPickerSheet(),
    );
    if (category == null || !context.mounted) return;

    final tripProvider = context.read<TripProvider>();
    await showAddDocumentSheet(
      context,
      onPicked: (documents) {
        for (final document in documents) {
          tripProvider.addTripDocument(tripId, document.copyWith(category: category));
        }
      },
    );
  }
}

class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
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
            Text('What kind of document?', style: theme.textTheme.titleLarge),
            const SizedBox(height: 14),
            for (final category in TripDocumentCategory.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: category.color.withValues(alpha: 0.14),
                  child: Icon(category.icon, color: category.color),
                ),
                title: Text(category.label),
                onTap: () => Navigator.of(context).pop(category),
              ),
          ],
        ),
      ),
    );
  }
}

class _TripDocumentsTab extends StatelessWidget {
  final String tripId;

  const _TripDocumentsTab({required this.tripId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tripProvider = context.watch<TripProvider>();
    final documents = tripProvider.current.documents;

    if (documents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_open_rounded, size: 48, color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 12),
              Text(
                'No trip documents yet',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Passports, insurance, visas, and other documents for the '
                'whole trip live here — tap + to add one.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final byCategory = <TripDocumentCategory, List<TravelDocument>>{};
    for (final doc in documents) {
      byCategory.putIfAbsent(doc.category ?? TripDocumentCategory.other, () => []).add(doc);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        for (final category in TripDocumentCategory.values)
          if (byCategory[category] != null) ...[
            Row(
              children: [
                Icon(category.icon, size: 18, color: category.color),
                const SizedBox(width: 8),
                Text(category.label, style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final document in byCategory[category]!)
                  DocumentCard(
                    document: document,
                    onPreview: () => _openViewer(context, document),
                    onRename: (newName) => context
                        .read<TripProvider>()
                        .renameTripDocument(tripId, document.id, newName),
                    onShare: () => _shareFile(document),
                    onDownload: () => _shareFile(document),
                    onDelete: () => context
                        .read<TripProvider>()
                        .removeTripDocument(tripId, document.id),
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
      ],
    );
  }

  void _openViewer(BuildContext context, TravelDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentViewerScreen(
          document: document,
          onRename: (newName) =>
              context.read<TripProvider>().renameTripDocument(tripId, document.id, newName),
          onDelete: () => context.read<TripProvider>().removeTripDocument(tripId, document.id),
        ),
      ),
    );
  }

  Future<void> _shareFile(TravelDocument document) async {
    await Share.shareXFiles([XFile.fromData(document.bytes, name: document.fileName)]);
  }
}

class _ByReservationTab extends StatelessWidget {
  final String tripId;

  const _ByReservationTab({required this.tripId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reservations = context.watch<ReservationsProvider>().forTrip(tripId)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    if (reservations.isEmpty) {
      return Center(
        child: Text(
          'No reservations yet',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reservations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final reservation = reservations[index];
        return _ReservationDocsRow(reservation: reservation);
      },
    );
  }
}

class _ReservationDocsRow extends StatelessWidget {
  final Reservation reservation;

  const _ReservationDocsRow({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = reservation.category.color;
    final count = reservation.attachments.length;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReservationDetailScreen(
              reservationId: reservation.id,
              scrollToDocuments: true,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(reservation.category.icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      reservation.provider,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: count > 0
                      ? theme.colorScheme.primary.withValues(alpha: 0.12)
                      : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  count == 1 ? '1 file' : '$count files',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: count > 0
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

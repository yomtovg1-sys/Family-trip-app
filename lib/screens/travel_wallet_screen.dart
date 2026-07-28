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
  String _query = '';
  DocumentTag? _selectedTag;

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
      body: Column(
        children: [
          _SearchAndTagBar(
            query: _query,
            selectedTag: _selectedTag,
            onQueryChanged: (value) => setState(() => _query = value),
            onTagSelected: (tag) => setState(
              () => _selectedTag = _selectedTag == tag ? null : tag,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TripDocumentsTab(tripId: trip.id, query: _query, tag: _selectedTag),
                _ByReservationTab(tripId: trip.id, query: _query, tag: _selectedTag),
              ],
            ),
          ),
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
          tripProvider.addTripDocument(
            tripId,
            document.copyWith(category: category, tag: category.defaultDocumentTag),
          );
        }
      },
    );
  }
}

class _SearchAndTagBar extends StatelessWidget {
  final String query;
  final DocumentTag? selectedTag;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<DocumentTag> onTagSelected;

  const _SearchAndTagBar({
    required this.query,
    required this.selectedTag,
    required this.onQueryChanged,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search documents…',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: onQueryChanged,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final tag in DocumentTag.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _TagChip(
                      tag: tag,
                      selected: selectedTag == tag,
                      onTap: () => onTagSelected(tag),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final DocumentTag tag;
  final bool selected;
  final VoidCallback onTap;

  const _TagChip({required this.tag, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected ? tag.color.withValues(alpha: 0.14) : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? tag.color.withValues(alpha: 0.5) : theme.colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tag.icon, size: 14, color: selected ? tag.color : theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                tag.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? tag.color : theme.colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
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
  final String query;
  final DocumentTag? tag;

  const _TripDocumentsTab({required this.tripId, required this.query, required this.tag});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tripProvider = context.watch<TripProvider>();
    final documents = _filter(tripProvider.current.documents);

    if (tripProvider.current.documents.isEmpty) {
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

    if (documents.isEmpty) {
      return Center(
        child: Text(
          'No documents match your search',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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

  List<TravelDocument> _filter(List<TravelDocument> documents) {
    final lowerQuery = query.trim().toLowerCase();
    return documents.where((doc) {
      final matchesTag = tag == null || doc.tag == tag;
      final matchesQuery = lowerQuery.isEmpty ||
          doc.fileName.toLowerCase().contains(lowerQuery) ||
          doc.tag.label.toLowerCase().contains(lowerQuery) ||
          (doc.category?.label.toLowerCase().contains(lowerQuery) ?? false);
      return matchesTag && matchesQuery;
    }).toList();
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
  final String query;
  final DocumentTag? tag;

  const _ByReservationTab({required this.tripId, required this.query, required this.tag});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allReservations = context.watch<ReservationsProvider>().forTrip(tripId)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    if (allReservations.isEmpty) {
      return Center(
        child: Text(
          'No reservations yet',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    final lowerQuery = query.trim().toLowerCase();
    final hasFilter = lowerQuery.isNotEmpty || tag != null;
    final reservations = hasFilter
        ? allReservations.where((r) => r.attachments.any((doc) {
              final matchesTag = tag == null || doc.tag == tag;
              final matchesQuery =
                  lowerQuery.isEmpty || doc.fileName.toLowerCase().contains(lowerQuery);
              return matchesTag && matchesQuery;
            })).toList()
        : allReservations;

    if (reservations.isEmpty) {
      return Center(
        child: Text(
          'No documents match your search',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reservations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _ReservationDocsRow(reservation: reservations[index]),
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
    final countLabel = count == 0
        ? 'No Documents'
        : count == 1
            ? '1 Document'
            : '$count Documents';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _openReservation(context),
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
                  IconButton(
                    tooltip: 'Add Document',
                    icon: Icon(Icons.add_circle_outline_rounded, color: theme.colorScheme.primary),
                    onPressed: () => _addDocument(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                count > 0 ? Icons.folder_rounded : Icons.folder_off_outlined,
                size: 14,
                color: count > 0 ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                countLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: count > 0 ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (reservation.attachments.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final document in reservation.attachments)
                  _DocumentNameChip(
                    document: document,
                    onTap: () => _openViewer(context, document),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _openReservation(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReservationDetailScreen(
          reservationId: reservation.id,
          scrollToDocuments: true,
        ),
      ),
    );
  }

  void _openViewer(BuildContext context, TravelDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentViewerScreen(
          document: document,
          onRename: (newName) => context
              .read<ReservationsProvider>()
              .renameAttachment(reservation.id, document.id, newName),
          onDelete: () => context
              .read<ReservationsProvider>()
              .removeAttachment(reservation.id, document.id),
        ),
      ),
    );
  }

  Future<void> _addDocument(BuildContext context) async {
    final provider = context.read<ReservationsProvider>();
    await showAddDocumentSheet(
      context,
      onPicked: (documents) {
        for (final document in documents) {
          provider.addAttachment(
            reservation.id,
            document.copyWith(tag: reservation.category.defaultDocumentTag),
          );
        }
      },
    );
  }
}

class _DocumentNameChip extends StatelessWidget {
  final TravelDocument document;
  final VoidCallback onTap;

  const _DocumentNameChip({required this.document, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  document.looksLikeQrCode ? Icons.qr_code_rounded : document.type.icon,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    document.fileName,
                    style: theme.textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

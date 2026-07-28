import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/reservation.dart';
import '../models/travel_document.dart';
import '../providers/reservations_provider.dart';
import '../widgets/documents/add_document_sheet.dart';
import '../widgets/documents/document_card.dart';
import 'add_reservation_screen.dart';
import 'document_viewer_screen.dart';

class ReservationDetailScreen extends StatefulWidget {
  final String reservationId;
  final bool scrollToDocuments;

  const ReservationDetailScreen({
    super.key,
    required this.reservationId,
    this.scrollToDocuments = false,
  });

  @override
  State<ReservationDetailScreen> createState() => _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  final _attachmentsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.scrollToDocuments) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToAttachments());
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReservationsProvider>();
    final reservation = provider.byId(widget.reservationId);

    if (reservation == null) {
      return const Scaffold(body: Center(child: Text('Reservation not found')));
    }

    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE, MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final color = reservation.category.color;

    return Scaffold(
      appBar: AppBar(
        title: Text(reservation.category.label),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddReservationScreen(editing: reservation),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _confirmDelete(context, reservation),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, Color.lerp(color, Colors.black, 0.35)!],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(reservation.category.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    if (reservation.subtype != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          reservation.subtype!,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        reservation.status.label,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  reservation.title,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  reservation.provider,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ActionsRow(reservation: reservation, onOpenDocuments: _scrollToAttachments),
          const SizedBox(height: 20),
          _InfoCard(
            children: [
              _InfoRow(
                icon: Icons.calendar_today_rounded,
                label: 'Date',
                value: dateFormat.format(reservation.dateTime),
              ),
              _InfoRow(
                icon: Icons.access_time_rounded,
                label: 'Time',
                value: timeFormat.format(reservation.dateTime),
              ),
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Location',
                value: reservation.location,
              ),
              _InfoRow(
                icon: Icons.confirmation_number_outlined,
                label: 'Confirmation #',
                value: reservation.confirmationNumber,
                trailing: IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  onPressed: () => _copyConfirmation(context, reservation.confirmationNumber),
                ),
              ),
              if (reservation.phone != null)
                _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: reservation.phone!),
              if (reservation.website != null)
                _InfoRow(icon: Icons.language_rounded, label: 'Website', value: reservation.website!),
              if (reservation.notes != null && reservation.notes!.isNotEmpty)
                _InfoRow(icon: Icons.notes_rounded, label: 'Notes', value: reservation.notes!),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            key: _attachmentsKey,
            children: [
              Text('Documents', style: theme.textTheme.titleMedium),
              const SizedBox(width: 8),
              if (reservation.attachments.isNotEmpty)
                Text(
                  '(${reservation.attachments.length})',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final document in reservation.attachments)
                DocumentCard(
                  document: document,
                  onPreview: () => _openViewer(context, reservation, document),
                  onRename: (newName) => context
                      .read<ReservationsProvider>()
                      .renameAttachment(reservation.id, document.id, newName),
                  onShare: () => _shareFile(document),
                  onDownload: () => _shareFile(document),
                  onDelete: () => context
                      .read<ReservationsProvider>()
                      .removeAttachment(reservation.id, document.id),
                ),
              AddDocumentTile(onTap: () => _uploadDocuments(context, reservation)),
            ],
          ),
        ],
      ),
    );
  }

  void _scrollToAttachments() {
    final context = _attachmentsKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 300));
    }
  }

  Future<void> _uploadDocuments(BuildContext context, Reservation reservation) async {
    final provider = context.read<ReservationsProvider>();
    await showAddDocumentSheet(
      context,
      onPicked: (documents) {
        for (final document in documents) {
          provider.addAttachment(reservation.id, document);
        }
      },
    );
  }

  void _openViewer(BuildContext context, Reservation reservation, TravelDocument document) {
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

  Future<void> _shareFile(TravelDocument document) async {
    await Share.shareXFiles([XFile.fromData(document.bytes, name: document.fileName)]);
  }

  void _copyConfirmation(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Confirmation number copied')),
    );
  }

  void _confirmDelete(BuildContext context, Reservation reservation) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete reservation?'),
        content: Text('This will remove "${reservation.title}" permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ReservationsProvider>().deleteReservation(reservation.id);
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback onOpenDocuments;

  const _ActionsRow({required this.reservation, required this.onOpenDocuments});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ActionButton(
            icon: Icons.map_rounded,
            label: 'Maps',
            onTap: () => _openMaps(reservation.location),
          ),
          if (reservation.phone != null)
            _ActionButton(
              icon: Icons.call_rounded,
              label: 'Call',
              onTap: () => _call(reservation.phone!),
            ),
          if (reservation.website != null)
            _ActionButton(
              icon: Icons.language_rounded,
              label: 'Website',
              onTap: () => _openWebsite(reservation.website!),
            ),
          _ActionButton(
            icon: Icons.copy_rounded,
            label: 'Copy #',
            onTap: () {
              Clipboard.setData(ClipboardData(text: reservation.confirmationNumber));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Confirmation number copied')),
              );
            },
          ),
          _ActionButton(
            icon: Icons.ios_share_rounded,
            label: 'Share',
            onTap: () => _shareReservation(reservation),
          ),
          _ActionButton(
            icon: Icons.folder_open_rounded,
            label: 'Documents',
            onTap: onOpenDocuments,
          ),
        ],
      ),
    );
  }

  Future<void> _openMaps(String location) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _call(String phone) async {
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _openWebsite(String website) async {
    await launchUrl(Uri.parse(website), mode: LaunchMode.externalApplication);
  }

  Future<void> _shareReservation(Reservation reservation) async {
    final dateFormat = DateFormat('MMM d, yyyy · h:mm a');
    final text = '${reservation.title}\n'
        '${dateFormat.format(reservation.dateTime)}\n'
        '${reservation.location}\n'
        'Confirmation #${reservation.confirmationNumber}\n'
        '${reservation.provider}';
    await Share.share(text, subject: reservation.title);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 6),
                Text(label, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 14),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

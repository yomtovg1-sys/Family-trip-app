import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/backup_meta.dart';
import '../models/cloud_account.dart';
import '../models/export_format.dart';
import '../models/sync_conflict.dart';
import '../models/sync_status.dart';
import '../providers/trip_provider.dart';
import '../services/backup_manager.dart';
import '../services/conflict_resolver.dart';
import '../services/settings_repository.dart';
import '../services/sync_service.dart';
import '../services/trip_export_service.dart';
import '../services/trip_import_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_section.dart';
import '../widgets/section_header.dart';

String _formatBytes(int bytes) {
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
  return '${(kb / 1024).toStringAsFixed(1)} MB';
}

String _formatWhen(DateTime dt) {
  final now = DateTime.now();
  final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
  final yesterday = now.subtract(const Duration(days: 1));
  final isYesterday = dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;
  final time = DateFormat('HH:mm').format(dt);
  if (isToday) return 'Today, $time';
  if (isYesterday) return 'Yesterday, $time';
  return '${DateFormat('MMM d').format(dt)}, $time';
}

/// Sync & Backup: works quietly in the background (see [BackupManager]) and
/// otherwise stays out of the way — this screen is where the family checks
/// in on it, not something they need to babysit.
class SyncBackupScreen extends StatefulWidget {
  const SyncBackupScreen({super.key});

  @override
  State<SyncBackupScreen> createState() => _SyncBackupScreenState();
}

class _SyncBackupScreenState extends State<SyncBackupScreen> {
  static const _exportService = TripExportService();
  static const _importService = TripImportService();
  static const _conflictResolver = ConflictResolver();

  bool _busy = false;
  ExportFormat _exportFormat = ExportFormat.json;

  @override
  Widget build(BuildContext context) {
    final backupManager = context.watch<BackupManager>();
    final syncService = context.watch<SyncService>();
    final trip = context.watch<TripProvider>().current.trip;

    return Scaffold(
      appBar: AppBar(title: const Text('Sync & Backup')),
      drawer: const AppDrawer(currentRoute: AppSection.syncBackupRoute),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          _SyncStatusCard(backupManager: backupManager, syncService: syncService),
          const SizedBox(height: 28),
          const SectionHeader(
            title: 'Backup',
            subtitle: 'Your trip data, saved on this device',
          ),
          const SizedBox(height: 12),
          _BackupActionsCard(
            backupManager: backupManager,
            busy: _busy,
            onManualBackup: () => _runManualBackup(backupManager),
            onRestore: () => _openRestoreSheet(backupManager),
          ),
          const SizedBox(height: 28),
          const SectionHeader(title: 'What Gets Backed Up'),
          const SizedBox(height: 12),
          const _WhatsBackedUpCard(),
          const SizedBox(height: 28),
          const SectionHeader(
            title: 'Sync Across Devices',
            subtitle: 'Sign in on another device and every trip appears',
          ),
          const SizedBox(height: 12),
          _SyncAcrossDevicesCard(
            syncService: syncService,
            busy: _busy,
            onSyncNow: () => _runSyncNow(syncService),
          ),
          const SizedBox(height: 28),
          SectionHeader(title: 'Export', subtitle: trip.name),
          const SizedBox(height: 12),
          _ExportCard(
            format: _exportFormat,
            onFormatChanged: (f) => setState(() => _exportFormat = f),
            busy: _busy,
            onExport: () => _runExport(backupManager, trip.id, trip.name),
          ),
          const SizedBox(height: 28),
          const SectionHeader(
            title: 'Import',
            subtitle: 'A backup file or a trip someone shared with you',
          ),
          const SizedBox(height: 12),
          _ImportCard(busy: _busy, onImport: () => _runImport(backupManager)),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Shared Trips'),
          const SizedBox(height: 12),
          _SharedTripsCard(account: syncService.connectedAccount, tripName: trip.name),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Security'),
          const SizedBox(height: 12),
          const _SecurityCard(),
        ],
      ),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _runManualBackup(BackupManager backupManager) async {
    setState(() => _busy = true);
    try {
      await backupManager.createManualBackup();
      _snack('Backup created.');
    } catch (_) {
      _snack("Couldn't create a backup. Please try again.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openRestoreSheet(BackupManager backupManager) async {
    final backups = await backupManager.listBackups();
    if (!mounted) return;
    if (backups.isEmpty) {
      _snack('No backups yet.');
      return;
    }
    final chosen = await showModalBottomSheet<BackupMeta>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RestoreSheet(backups: backups),
    );
    if (chosen == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore this backup?'),
        content: Text(
          'This replaces your current trip data with the backup from ${_formatWhen(chosen.createdAt)}. '
          "A safety backup of what's here now will be taken first.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Restore')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final ok = await backupManager.restoreFromBackup(chosen.id);
      _snack(ok ? 'Backup restored.' : "That backup couldn't be found anymore.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runSyncNow(SyncService syncService) async {
    setState(() => _busy = true);
    try {
      await syncService.syncNow();
      if (!mounted) return;
      switch (syncService.status) {
        case SyncStatus.synced:
        case SyncStatus.idle:
          _snack('Synced successfully.');
        case SyncStatus.offline:
          _snack('Backed up locally — cloud sync will finish once a provider is connected.');
        case SyncStatus.error:
          _snack(syncService.lastErrorMessage ?? 'Sync failed.');
        case SyncStatus.syncing:
        case SyncStatus.conflict:
          break;
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runExport(BackupManager backupManager, String tripId, String tripName) async {
    if (!_exportFormat.isAvailable) return;
    setState(() => _busy = true);
    try {
      final snapshot = backupManager.buildTripSnapshot(tripId);
      final fileName = _exportFormat.fileName(tripName);
      switch (_exportFormat) {
        case ExportFormat.json:
          final bytes = _exportService.exportAsJson(snapshot);
          await Share.shareXFiles([
            XFile.fromData(bytes, name: fileName, mimeType: 'application/json'),
          ]);
        case ExportFormat.pdf:
          final bytes = await _exportService.exportAsPdf(snapshot);
          await Printing.sharePdf(bytes: bytes, filename: fileName);
        case ExportFormat.zip:
          break;
      }
    } catch (_) {
      _snack("Couldn't export the trip.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runImport(BackupManager backupManager) async {
    final bytes = await _importService.pickImportFile();
    if (bytes == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final existing = [
        for (final dashboard in backupManager.tripProvider.all) backupManager.buildTripSnapshot(dashboard.trip.id),
      ];
      final outcome = _importService.parseAndValidate(bytes, existingTrips: existing);

      if (!outcome.isValid) {
        _snack(outcome.errorMessage ?? "Couldn't read that file.");
        return;
      }

      for (final ready in outcome.readyTrips) {
        backupManager.applyTripSnapshot(ready);
      }
      if (outcome.packingItems != null) {
        backupManager.packingProvider.replaceAll(outcome.packingItems!);
      }

      var resolvedCount = 0;
      for (final conflict in outcome.conflicts) {
        if (!mounted) break;
        final choice = await _showConflictSheet(conflict);
        if (choice == null) continue;
        final resolved = _conflictResolver.resolve(conflict, choice);
        backupManager.applyTripSnapshot(resolved);
        resolvedCount++;
      }

      final total = outcome.readyTrips.length + resolvedCount;
      _snack(total == 0 ? 'Nothing new to import.' : 'Imported $total trip${total == 1 ? '' : 's'}.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<ConflictChoice?> _showConflictSheet(SyncConflict conflict) {
    return showModalBottomSheet<ConflictChoice>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _ConflictSheet(conflict: conflict),
    );
  }
}

class _SyncStatusCard extends StatelessWidget {
  final BackupManager backupManager;
  final SyncService syncService;

  const _SyncStatusCard({required this.backupManager, required this.syncService});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = backupManager.isBackingUp ? SyncStatus.syncing : syncService.status;
    final latest = backupManager.latestBackup;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusIcon(status: status),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(status.label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const Divider(height: 28),
            _InfoRow(
              icon: Icons.history_rounded,
              label: 'Last backup',
              value: latest != null ? _formatWhen(latest.createdAt) : 'No backups yet',
            ),
            const SizedBox(height: 10),
            FutureBuilder<int>(
              future: backupManager.storageUsedBytes(),
              builder: (context, snapshot) => _InfoRow(
                icon: Icons.sd_storage_rounded,
                label: 'Storage used',
                value: snapshot.hasData ? _formatBytes(snapshot.data!) : '…',
              ),
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.person_rounded,
              label: 'Connected account',
              value: syncService.connectedAccount?.email ?? 'Not signed in',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final SyncStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == SyncStatus.syncing) {
      return const SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(strokeWidth: 2.6),
      );
    }
    final (icon, color) = switch (status) {
      SyncStatus.synced || SyncStatus.idle => (Icons.check_circle_rounded, const Color(0xFF2F9E44)),
      SyncStatus.offline => (Icons.cloud_off_rounded, const Color(0xFFE8A94E)),
      SyncStatus.error => (Icons.error_rounded, const Color(0xFFE53935)),
      SyncStatus.conflict => (Icons.warning_rounded, const Color(0xFFE8590C)),
      SyncStatus.syncing => (Icons.sync_rounded, const Color(0xFF2F9E44)),
    };
    return Icon(icon, color: color, size: 26);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _BackupActionsCard extends StatelessWidget {
  final BackupManager backupManager;
  final bool busy;
  final VoidCallback onManualBackup;
  final VoidCallback onRestore;

  const _BackupActionsCard({
    required this.backupManager,
    required this.busy,
    required this.onManualBackup,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Automatic backups'),
              subtitle: const Text('Backs up whenever your trip data changes'),
              value: backupManager.autoBackupEnabled,
              onChanged: (value) => backupManager.setAutoBackupEnabled(value),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy ? null : onManualBackup,
                    icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                    label: const Text('Back Up Now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : onRestore,
                    icon: const Icon(Icons.settings_backup_restore_rounded, size: 18),
                    label: const Text('Restore'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RestoreSheet extends StatelessWidget {
  final List<BackupMeta> backups;

  const _RestoreSheet({required this.backups});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Restore from backup', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: backups.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final meta = backups[index];
                  return ListTile(
                    leading: const Icon(Icons.history_rounded),
                    title: Text(_formatWhen(meta.createdAt)),
                    subtitle: Text('${meta.trigger.label} · ${meta.tripCount} trips · ${meta.sizeLabel}'),
                    onTap: () => Navigator.pop(context, meta),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatsBackedUpCard extends StatefulWidget {
  const _WhatsBackedUpCard();

  @override
  State<_WhatsBackedUpCard> createState() => _WhatsBackedUpCardState();
}

class _WhatsBackedUpCardState extends State<_WhatsBackedUpCard> {
  bool? _includeAi;

  static const _categories = [
    (Icons.card_travel_rounded, 'Trips'),
    (Icons.travel_explore_rounded, 'Explore Places'),
    (Icons.map_rounded, 'Map Locations'),
    (Icons.confirmation_number_rounded, 'Reservations'),
    (Icons.account_balance_wallet_rounded, 'Travel Wallet Documents'),
    (Icons.savings_rounded, 'Expenses'),
    (Icons.checklist_rounded, 'Packing Lists'),
    (Icons.photo_library_rounded, 'Memories'),
    (Icons.settings_rounded, 'App Settings'),
  ];

  @override
  void initState() {
    super.initState();
    context.read<SettingsRepository>().getIncludeAiConversations().then((value) {
      if (mounted) setState(() => _includeAi = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        child: Column(
          children: [
            for (final (icon, label) in _categories)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(icon, color: theme.colorScheme.primary),
                title: Text(label),
                trailing: const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF2F9E44)),
                dense: true,
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary),
              title: const Text('AI Conversations'),
              subtitle: const Text('Optional'),
              trailing: Switch(
                value: _includeAi ?? false,
                onChanged: _includeAi == null
                    ? null
                    : (value) {
                        setState(() => _includeAi = value);
                        context.read<SettingsRepository>().setIncludeAiConversations(value);
                      },
              ),
              dense: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncAcrossDevicesCard extends StatelessWidget {
  final SyncService syncService;
  final bool busy;
  final VoidCallback onSyncNow;

  const _SyncAcrossDevicesCard({required this.syncService, required this.busy, required this.onSyncNow});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              syncService.isCloudConnected
                  ? '${syncService.pendingChangesCount} change(s) waiting to sync.'
                  : 'Not connected to a cloud provider yet — your backups stay on this device '
                      'until one is. Once connected, trips will sync automatically to every '
                      'device signed into this account, and any conflicting edit will ask you '
                      'to choose which version to keep.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: busy ? null : onSyncNow,
              icon: const Icon(Icons.sync_rounded, size: 18),
              label: const Text('Sync Now'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportCard extends StatelessWidget {
  final ExportFormat format;
  final ValueChanged<ExportFormat> onFormatChanged;
  final bool busy;
  final VoidCallback onExport;

  const _ExportCard({
    required this.format,
    required this.onFormatChanged,
    required this.busy,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RadioGroup<ExportFormat>(
              groupValue: format,
              onChanged: (value) {
                if (value != null) onFormatChanged(value);
              },
              child: Column(
                children: [
                  for (final option in ExportFormat.values.where((f) => f.isAvailable))
                    RadioListTile<ExportFormat>(
                      contentPadding: EdgeInsets.zero,
                      value: option,
                      title: Text(option.label),
                      subtitle: Text(option.description),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: busy ? null : onExport,
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: const Text('Export Trip'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportCard extends StatelessWidget {
  final bool busy;
  final VoidCallback onImport;

  const _ImportCard({required this.busy, required this.onImport});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a .json file — a full backup or a trip someone shared with you. '
              "It's checked before anything changes, and if a trip already exists on this "
              "device you'll be asked how to handle it.",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: busy ? null : onImport,
              icon: const Icon(Icons.file_upload_outlined, size: 18),
              label: const Text('Choose File'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConflictSheet extends StatelessWidget {
  final SyncConflict conflict;

  const _ConflictSheet({required this.conflict});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 28),
            const SizedBox(height: 10),
            Text('"${conflict.tripName}" was modified on another device.', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'This device: ${_formatWhen(conflict.localModifiedAt)}  ·  Incoming: ${_formatWhen(conflict.incomingModifiedAt)}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            for (final choice in ConflictChoice.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, choice),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(choice.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        choice.description,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SharedTripsCard extends StatelessWidget {
  final CloudAccountInfo? account;
  final String tripName;

  const _SharedTripsCard({required this.account, required this.tripName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.star_rounded)),
              title: Text(account?.displayName ?? 'You'),
              subtitle: const Text('Owner'),
            ),
            const SizedBox(height: 8),
            Text(
              'Collaboration isn\'t built yet, but every trip already tracks an owner, editors, and '
              'view-only members underneath — so inviting family here will be a small addition later, '
              'not a rebuild.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard();

  static const _points = [
    'Backups are private to your account.',
    "Your data stays on this device until a cloud provider is connected — nothing is uploaded today.",
    'Once connected, cloud backups will be encrypted in transit and at rest.',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final point in _points)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_rounded, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(point, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

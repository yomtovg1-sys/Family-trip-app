import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/google_maps_import.dart';
import '../providers/places_provider.dart';
import '../services/google_maps_import_service.dart';

enum _Stage { loadingLists, choosing, importing, summary }

/// "Import from Google Maps": explains what's about to happen, lets the
/// family choose all saved places or just specific lists (Favorites, Want
/// to Go, Starred, custom lists), then imports with a progress state and a
/// final imported/duplicates/failed summary.
///
/// Backed by [GoogleMapsImportService] — [MockGoogleMapsImportService] for
/// now, so the whole flow works before real Google auth is wired up.
class ImportGoogleMapsScreen extends StatefulWidget {
  final String tripId;
  final GoogleMapsImportService importService;

  const ImportGoogleMapsScreen({
    super.key,
    required this.tripId,
    this.importService = const MockGoogleMapsImportService(),
  });

  @override
  State<ImportGoogleMapsScreen> createState() => _ImportGoogleMapsScreenState();
}

class _ImportGoogleMapsScreenState extends State<ImportGoogleMapsScreen> {
  _Stage _stage = _Stage.loadingLists;
  List<GoogleMapsSavedList> _lists = [];
  final Set<String> _selectedListIds = {};
  bool _importAll = true;
  GoogleMapsImportResult? _result;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    final lists = await widget.importService.fetchLists();
    if (!mounted) return;
    setState(() {
      _lists = lists;
      _stage = _Stage.choosing;
    });
  }

  Future<void> _runImport() async {
    setState(() => _stage = _Stage.importing);
    final candidates = await widget.importService.fetchPlaces(
      listIds: _importAll ? null : _selectedListIds.toList(),
    );
    if (!mounted) return;
    final result = context.read<PlacesProvider>().importPlaces(widget.tripId, candidates);
    if (!mounted) return;
    setState(() {
      _result = result;
      _stage = _Stage.summary;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import from Google Maps')),
      body: switch (_stage) {
        _Stage.loadingLists => const Center(child: CircularProgressIndicator()),
        _Stage.choosing => _ChoosingView(
            lists: _lists,
            importAll: _importAll,
            selectedListIds: _selectedListIds,
            onImportAllChanged: (v) => setState(() => _importAll = v),
            onListToggled: (id, selected) => setState(() {
              if (selected) {
                _selectedListIds.add(id);
              } else {
                _selectedListIds.remove(id);
              }
            }),
            onImport: (_importAll || _selectedListIds.isNotEmpty) ? _runImport : null,
          ),
        _Stage.importing => const _ImportingView(),
        _Stage.summary => _SummaryView(result: _result!, onDone: () => Navigator.of(context).pop(true)),
      },
    );
  }
}

class _ChoosingView extends StatelessWidget {
  final List<GoogleMapsSavedList> lists;
  final bool importAll;
  final Set<String> selectedListIds;
  final ValueChanged<bool> onImportAllChanged;
  final void Function(String id, bool selected) onListToggled;
  final VoidCallback? onImport;

  const _ChoosingView({
    required this.lists,
    required this.importAll,
    required this.selectedListIds,
    required this.onImportAllChanged,
    required this.onListToggled,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalPlaces = lists.fold<int>(0, (sum, l) => sum + l.placeCount);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Text('📥', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Import your saved Google Maps places into this trip.",
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          child: RadioGroup<bool>(
            groupValue: importAll,
            onChanged: (v) => onImportAllChanged(v ?? true),
            child: Column(
              children: [
                RadioListTile<bool>(
                  value: true,
                  title: const Text('Import all saved places'),
                  subtitle: Text('$totalPlaces places across ${lists.length} lists'),
                ),
                RadioListTile<bool>(
                  value: false,
                  title: const Text('Import selected lists only'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedOpacity(
          opacity: importAll ? 0.4 : 1,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: importAll,
            child: Column(
              children: [
                for (final list in lists)
                  Card(
                    margin: const EdgeInsets.only(top: 8),
                    child: CheckboxListTile(
                      value: selectedListIds.contains(list.id),
                      onChanged: (v) => onListToggled(list.id, v ?? false),
                      title: Text('${list.type.emoji} ${list.name}'),
                      subtitle: Text('${list.placeCount} places'),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onImport,
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          child: const Text('Import'),
        ),
        const SizedBox(height: 8),
        Text(
          "We'll skip anything that looks like a place you've already saved.",
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ImportingView extends StatelessWidget {
  const _ImportingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text('Importing your places…', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(
            'Matching against places already saved to this trip.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SummaryView extends StatelessWidget {
  final GoogleMapsImportResult result;
  final VoidCallback onDone;

  const _SummaryView({required this.result, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.check_rounded, color: theme.colorScheme.primary, size: 36),
          ),
          const SizedBox(height: 20),
          Text('Import complete', style: theme.textTheme.titleLarge),
          const SizedBox(height: 20),
          _SummaryRow(
            emoji: '✅',
            label: 'places imported',
            value: result.importedCount,
            color: const Color(0xFF2F9E44),
          ),
          _SummaryRow(
            emoji: '♻️',
            label: 'duplicates skipped',
            value: result.duplicatesSkipped,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          _SummaryRow(
            emoji: '⚠️',
            label: 'failed',
            value: result.failed,
            color: const Color(0xFFE8590C),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onDone,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String emoji;
  final String label;
  final int value;
  final Color color;

  const _SummaryRow({required this.emoji, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            '$value',
            style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

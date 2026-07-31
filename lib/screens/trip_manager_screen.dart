import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/document_category.dart';
import '../models/trip.dart';
import '../models/trip_template.dart';
import '../providers/memories_provider.dart';
import '../providers/packing_provider.dart';
import '../providers/places_provider.dart';
import '../providers/reservations_provider.dart';
import '../providers/tasks_provider.dart';
import '../providers/trip_provider.dart';
import '../services/personal_vault.dart';
import '../services/trip_copy_service.dart';
import '../services/trip_manager.dart';
import '../utils/currency.dart';
import '../utils/world_countries.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_section.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/country_picker_sheet.dart';
import '../widgets/destination_cover_image.dart';
import '../widgets/emoji_text.dart';

/// The Trip Manager: the visible face of [TripManager]. This is where a
/// family creates a trip (optionally attaching Personal Vault documents and
/// starting from a template), sees every trip at a glance, and moves data
/// between trips — the operations [TripManager], [TripLinkService], and
/// [TripCopyService] make possible.
class TripManagerScreen extends StatelessWidget {
  const TripManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tripManager = context.watch<TripManager>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Trip Manager')),
      drawer: const AppDrawer(currentRoute: AppSection.tripManagerRoute),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateTripScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Trip'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Text(
            'Every trip below shares one Personal Vault and can copy data to any other trip.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          for (final trip in tripManager.trips)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _TripCard(trip: trip, isActive: trip.id == tripManager.currentTrip.id),
            ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  final bool isActive;

  const _TripCard({required this.trip, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    final vaultDocs = context.watch<TripManager>().vaultDocumentsFor(trip.id);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isActive ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isActive ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.read<TripManager>().selectTrip(trip.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  EmojiText(trip.flagEmoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(trip.name, style: theme.textTheme.titleSmall, overflow: TextOverflow.ellipsis),
                        Text(
                          '${trip.destination} · ${dateFormat.format(trip.startDate)}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Active',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (value) => _handleMenu(context, value),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit Trip')),
                      PopupMenuItem(value: 'vault', child: Text('Attached Vault Items')),
                      PopupMenuItem(value: 'copy', child: Text('Copy/Move Data…')),
                      PopupMenuItem(value: 'template', child: Text('Apply Template')),
                    ],
                  ),
                ],
              ),
              if (vaultDocs.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final doc in vaultDocs)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: const Icon(Icons.check_rounded, size: 16),
                        label: Text(doc.displayName, style: theme.textTheme.labelSmall),
                        backgroundColor: doc.category.color.withValues(alpha: 0.12),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenu(BuildContext context, String value) {
    switch (value) {
      case 'edit':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EditTripScreen(trip: trip)),
        );
      case 'vault':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => _VaultLinkSheet(tripId: trip.id),
        );
      case 'copy':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => _CopyMoveSheet(sourceTripId: trip.id),
        );
      case 'template':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => _TemplateSheet(tripId: trip.id),
        );
    }
  }
}

class _VaultLinkSheet extends StatelessWidget {
  final String tripId;

  const _VaultLinkSheet({required this.tripId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final documents = context.watch<PersonalVault>().documents;
    final tripManager = context.watch<TripManager>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Personal Vault items', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Attach documents by reference — nothing here is duplicated.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            if (documents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Your Personal Vault is empty. Add documents there first.'),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final doc in documents)
                      CheckboxListTile(
                        value: tripManager.vaultLinksFor(tripId).any((l) => l.vaultDocumentId == doc.id),
                        title: Text(doc.displayName),
                        subtitle: Text(doc.category.label),
                        onChanged: (checked) {
                          if (checked ?? false) {
                            context.read<TripManager>().attachVaultDocument(tripId, doc.id);
                          } else {
                            context.read<TripManager>().detachVaultDocument(tripId, doc.id);
                          }
                        },
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CopyMoveSheet extends StatefulWidget {
  final String sourceTripId;

  const _CopyMoveSheet({required this.sourceTripId});

  @override
  State<_CopyMoveSheet> createState() => _CopyMoveSheetState();
}

class _CopyMoveSheetState extends State<_CopyMoveSheet> {
  String? _destinationTripId;
  bool _move = false;
  final Set<TripDataCategory> _categories = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trips = context.watch<TripManager>().trips.where((t) => t.id != widget.sourceTripId).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Copy or move data', style: theme.textTheme.titleMedium),
            const SizedBox(height: 14),
            if (trips.isEmpty)
              const Text('Create another trip first.')
            else ...[
              DropdownButtonFormField<String>(
                initialValue: _destinationTripId,
                decoration: const InputDecoration(labelText: 'To trip'),
                items: [
                  for (final trip in trips)
                    DropdownMenuItem(value: trip.id, child: EmojiText('${trip.flagEmoji} ${trip.name}')),
                ],
                onChanged: (value) => setState(() => _destinationTripId = value),
              ),
              const SizedBox(height: 14),
              for (final category in TripDataCategory.values)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _categories.contains(category),
                  title: Text(category.label),
                  subtitle: category.isAvailable ? null : const Text('Coming soon'),
                  onChanged: !category.isAvailable
                      ? null
                      : (checked) => setState(() {
                            if (checked ?? false) {
                              _categories.add(category);
                            } else {
                              _categories.remove(category);
                            }
                          }),
                ),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Copy'), icon: Icon(Icons.copy_rounded)),
                  ButtonSegment(value: true, label: Text('Move'), icon: Icon(Icons.drive_file_move_rounded)),
                ],
                selected: {_move},
                onSelectionChanged: (selection) => setState(() => _move = selection.first),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _destinationTripId == null || _categories.isEmpty ? null : () => _confirm(context),
                  child: Text(_move ? 'Move Data' : 'Copy Data'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirm(BuildContext context) {
    final service = TripCopyService(
      reservationsProvider: context.read<ReservationsProvider>(),
      placesProvider: context.read<PlacesProvider>(),
      packingProvider: context.read<PackingProvider>(),
      tripProvider: context.read<TripProvider>(),
      memoriesProvider: context.read<MemoriesProvider>(),
    );
    final result = service.copy(
      fromTripId: widget.sourceTripId,
      toTripId: _destinationTripId!,
      categories: _categories,
      move: _move,
    );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_move ? 'Moved' : 'Copied'} ${result.totalCopied} item(s).')),
    );
  }
}

class _TemplateSheet extends StatelessWidget {
  final String tripId;

  const _TemplateSheet({required this.tripId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templates = context.watch<TripManager>().templates;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apply a template', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final template in templates)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: ListTile(
                  leading: EmojiText(template.emoji, style: const TextStyle(fontSize: 22)),
                  title: Text(template.name),
                  subtitle: Text(template.description),
                  onTap: () => _confirmApply(context, template),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmApply(BuildContext context, TripTemplate template) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Apply ${template.name}?',
      message: 'Adds ${template.packingItems.length} packing item(s), '
          '${template.favoritePlaces.length} favorite place(s), and '
          '${template.checklist.length} checklist item(s) to this trip.',
      confirmLabel: 'Apply',
    );
    if (!confirmed || !context.mounted) return;

    context.read<TripManager>().applyTemplate(
          tripId: tripId,
          templateId: template.id,
          packingProvider: context.read<PackingProvider>(),
          placesProvider: context.read<PlacesProvider>(),
          tasksProvider: context.read<TasksProvider>(),
        );
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${template.name} applied.')),
      );
    }
  }
}

/// The simplest possible way to start a trip: choose a country, choose
/// travel dates, done. Everything else a trip needs — name, flag, currency,
/// timezone, and a landmark-matched cover — is filled in automatically from
/// the country, so there's no photo to pick and no name to type. Personal
/// Vault attachments and starting from a [TripTemplate] stay available as
/// optional extras; only the country and dates are required.
class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  DateTime _startDate = DateTime.now().add(const Duration(days: 30));
  DateTime _endDate = DateTime.now().add(const Duration(days: 37));
  final Set<String> _selectedVaultIds = {};
  String? _templateId;
  Country? _selectedCountry;

  Future<void> _pickCountry() async {
    final picked = await showCountryPicker(context, current: _selectedCountry);
    if (picked != null) setState(() => _selectedCountry = picked);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final vaultDocuments = context.watch<PersonalVault>().documents;
    final templates = context.watch<TripManager>().templates;
    final theme = Theme.of(context);
    final country = _selectedCountry;

    return Scaffold(
      appBar: AppBar(title: const Text('New Trip')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: country == null
                  ? Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const EmojiText('🌍', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 8),
                          Text(
                            'Pick a country to see your cover',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : DestinationCoverImage(cover: country),
            ),
          ),
          const SizedBox(height: 20),
          Text('Country', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          _CountrySelectorTile(country: country, onTap: _pickCountry),
          if (country != null) ...[
            const SizedBox(height: 8),
            Text(
              '${country.currency} · ${_shortTimezone(country.timezone)}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 20),
          _DatePickerRow(
            label: 'Start',
            date: _startDate,
            dateFormat: dateFormat,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _startDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
              );
              if (picked != null) {
                setState(() {
                  _startDate = picked;
                  if (_endDate.isBefore(_startDate)) {
                    _endDate = _startDate.add(const Duration(days: 7));
                  }
                });
              }
            },
          ),
          _DatePickerRow(
            label: 'End',
            date: _endDate,
            dateFormat: dateFormat,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _endDate,
                firstDate: _startDate,
                lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
              );
              if (picked != null) setState(() => _endDate = picked);
            },
          ),
          const SizedBox(height: 24),
          Text('Attach from Personal Vault (optional)', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'These stay referenced, never duplicated.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          if (vaultDocuments.isEmpty)
            const Text('Your Personal Vault is empty.')
          else
            for (final doc in vaultDocuments)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _selectedVaultIds.contains(doc.id),
                title: Text(doc.displayName),
                subtitle: Text(doc.category.label),
                onChanged: (checked) => setState(() {
                  if (checked ?? false) {
                    _selectedVaultIds.add(doc.id);
                  } else {
                    _selectedVaultIds.remove(doc.id);
                  }
                }),
              ),
          const SizedBox(height: 24),
          Text('Start from a template (optional)', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            initialValue: _templateId,
            decoration: const InputDecoration(labelText: 'Template'),
            items: [
              const DropdownMenuItem(value: null, child: Text('None')),
              for (final template in templates)
                DropdownMenuItem(value: template.id, child: EmojiText('${template.emoji} ${template.name}')),
            ],
            onChanged: (value) => setState(() => _templateId = value),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: country == null ? null : _submit,
            child: const Text('Create Trip'),
          ),
          if (country == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Choose a country to continue.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  void _submit() {
    final country = _selectedCountry;
    if (country == null) return;

    final tripManager = context.read<TripManager>();
    final trip = tripManager.createTrip(
      name: country.name,
      destination: country.name,
      flagEmoji: country.flagEmoji,
      startDate: _startDate,
      endDate: _endDate,
      country: country.name,
      currency: country.currency,
      timezone: country.timezone,
      vaultDocumentIds: _selectedVaultIds.toList(),
    );

    if (_templateId != null) {
      tripManager.applyTemplate(
        tripId: trip.id,
        templateId: _templateId!,
        packingProvider: context.read<PackingProvider>(),
        placesProvider: context.read<PlacesProvider>(),
        tasksProvider: context.read<TasksProvider>(),
      );
    }

    Navigator.of(context).pop();
  }
}

/// Full edit for an existing trip. Changing the country auto-updates the
/// flag, currency, and cover — unless a custom photo is already set, which
/// always wins over the auto cover until explicitly removed. The currency
/// stays editable afterward as a manual override.
class EditTripScreen extends StatefulWidget {
  final Trip trip;

  const EditTripScreen({super.key, required this.trip});

  @override
  State<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends State<EditTripScreen> {
  late Country? _country;
  late DateTime _startDate;
  late DateTime _endDate;
  late String _currency;
  Uint8List? _customCoverBytes;

  @override
  void initState() {
    super.initState();
    _country = countryByName(widget.trip.country);
    _startDate = widget.trip.startDate;
    _endDate = widget.trip.endDate;
    _currency = widget.trip.currency;
    _customCoverBytes = widget.trip.photoBytes;
  }

  Future<void> _pickCountry() async {
    final picked = await showCountryPicker(context, current: _country);
    if (picked == null) return;
    setState(() {
      _country = picked;
      _currency = picked.currency;
    });
  }

  Future<void> _pickCustomCover() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _customCoverBytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final theme = Theme.of(context);
    final country = _country;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Trip')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          Text('Cover photo', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_customCoverBytes != null)
                    Image.memory(_customCoverBytes!, fit: BoxFit.cover)
                  else if (country != null)
                    DestinationCoverImage(cover: country)
                  else
                    Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const EmojiText('🌍', style: TextStyle(fontSize: 48)),
                    ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_customCoverBytes != null) ...[
                          FilledButton.tonalIcon(
                            onPressed: () => setState(() => _customCoverBytes = null),
                            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                            label: const Text('Use auto cover'),
                          ),
                          const SizedBox(width: 8),
                        ],
                        FilledButton.tonalIcon(
                          onPressed: _pickCustomCover,
                          icon: const Icon(Icons.photo_library_rounded, size: 18),
                          label: Text(_customCoverBytes == null ? 'Choose photo' : 'Change photo'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Country', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          _CountrySelectorTile(country: country, onTap: _pickCountry),
          const SizedBox(height: 20),
          _DatePickerRow(
            label: 'Start',
            date: _startDate,
            dateFormat: dateFormat,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _startDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
                lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
              );
              if (picked != null) {
                setState(() {
                  _startDate = picked;
                  if (_endDate.isBefore(_startDate)) {
                    _endDate = _startDate.add(const Duration(days: 7));
                  }
                });
              }
            },
          ),
          _DatePickerRow(
            label: 'End',
            date: _endDate,
            dateFormat: dateFormat,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _endDate,
                firstDate: _startDate,
                lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
              );
              if (picked != null) setState(() => _endDate = picked);
            },
          ),
          const SizedBox(height: 20),
          Text('Currency', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Auto-set from the country — override it here if needed.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _currency,
            decoration: const InputDecoration(labelText: 'Currency'),
            items: [
              for (final code in supportedCurrencies) DropdownMenuItem(value: code, child: Text(code)),
            ],
            onChanged: (value) => setState(() => _currency = value ?? _currency),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: country == null ? null : _save,
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _save() {
    final country = _country;
    if (country == null) return;

    final updated = widget.trip.copyWith(
      name: country.name,
      destination: country.name,
      flagEmoji: country.flagEmoji,
      country: country.name,
      startDate: _startDate,
      endDate: _endDate,
      currency: _currency,
      timezone: country.timezone,
      photoBytes: _customCoverBytes,
      clearPhotoBytes: _customCoverBytes == null,
    );
    context.read<TripManager>().upsertTrip(updated);
    Navigator.of(context).pop();
  }
}

String _shortTimezone(String iana) => iana.split('/').last.replaceAll('_', ' ');

class _CountrySelectorTile extends StatelessWidget {
  final Country? country;
  final VoidCallback onTap;

  const _CountrySelectorTile({required this.country, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            if (country != null)
              EmojiText(country!.flagEmoji, style: const TextStyle(fontSize: 22))
            else
              Icon(Icons.public_rounded, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                country?.name ?? 'Choose a country',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: country == null ? theme.colorScheme.onSurfaceVariant : null,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded),
          ],
        ),
      ),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  final String label;
  final DateTime date;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  const _DatePickerRow({
    required this.label,
    required this.date,
    required this.dateFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(width: 50, child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
            const Icon(Icons.calendar_today_rounded, size: 16),
            const SizedBox(width: 8),
            Text(dateFormat.format(date)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/place.dart';
import '../models/place_draft.dart';
import '../providers/places_provider.dart';
import '../providers/trip_provider.dart';
import '../utils/currency.dart';
import '../widgets/places/star_rating.dart';
import 'pick_location_screen.dart';

/// The manual-entry / review / edit form for a saved place. Used directly
/// for "Manual entry", and as the shared review step every other capture
/// method (search, pasted URL, screenshot scan, website) lands on with a
/// pre-filled [draft] so the traveler only has to confirm, not retype.
class AddPlaceScreen extends StatefulWidget {
  final PlaceDraft? draft;
  final SavedPlace? editing;

  const AddPlaceScreen({super.key, this.draft, this.editing});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _areaController;
  late final TextEditingController _notesController;
  late final TextEditingController _costController;

  PlaceCategory? _category;
  double? _latitude;
  double? _longitude;
  int _priority = 3;
  Duration? _duration;
  bool _isFavorite = false;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    final draft = widget.draft;

    _nameController = TextEditingController(text: editing?.name ?? draft?.name ?? '');
    _areaController = TextEditingController(text: editing?.area ?? draft?.area ?? '');
    _notesController = TextEditingController(text: editing?.notes ?? draft?.notes ?? '');
    _costController = TextEditingController(
      text: editing?.estimatedCost != null ? editing!.estimatedCost!.toStringAsFixed(0) : '',
    );
    _category = editing?.category ?? draft?.category;
    _latitude = editing?.latitude ?? draft?.latitude;
    _longitude = editing?.longitude ?? draft?.longitude;
    _priority = editing?.priority ?? 3;
    _duration = editing?.estimatedDuration;
    _isFavorite = editing?.isFavorite ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _notesController.dispose();
    _costController.dispose();
    super.dispose();
  }

  bool get _hasCoordinates => _latitude != null && _longitude != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trip = context.watch<TripProvider>().current.trip;
    final isReview = !_isEditing && widget.draft != null;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Place' : (isReview ? 'Review Place' : 'Add Place'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            if (isReview)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary, size: 18),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Review the details below and edit anything before saving.',
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Text('Location', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickLocation,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.map_rounded, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _hasCoordinates
                            ? '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                            : 'Tap to choose on the map',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            if (!_hasCoordinates)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  'Coordinates are required',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _areaController,
              decoration: const InputDecoration(labelText: 'Area / City'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            Text('Category', style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                for (final category in PlaceCategory.values)
                  _CategoryButton(
                    category: category,
                    selected: _category == category,
                    onTap: () => setState(() => _category = category),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Text('Priority', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            StarRating(value: _priority, size: 30, onChanged: (v) => setState(() => _priority = v)),
            const SizedBox(height: 20),
            Text('Estimated duration (optional)', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _DurationChips(value: _duration, onChanged: (v) => setState(() => _duration = v)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _costController,
              decoration: InputDecoration(
                labelText: 'Estimated cost (optional)',
                prefixText: '${currencySymbol(trip.currency)} ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Favorite'),
              secondary: const Icon(Icons.favorite_rounded, color: Color(0xFFE53935)),
              value: _isFavorite,
              onChanged: (v) => setState(() => _isFavorite = v),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _canSave ? _save : null,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: Text(_isEditing ? 'Save Changes' : 'Save Place'),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canSave => _hasCoordinates && _category != null;

  Future<void> _pickLocation() async {
    final trip = context.read<TripProvider>().current;
    final anchor = _hasCoordinates
        ? LatLng(_latitude!, _longitude!)
        : () {
            final sim = context.read<PlacesProvider>().simulatedCurrentLocation(trip.trip.id);
            return sim != null ? LatLng(sim.latitude, sim.longitude) : const LatLng(39.0968, -120.0324);
          }();

    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (_) => PickLocationScreen(initialCenter: anchor)),
    );
    if (picked != null) {
      setState(() {
        _latitude = picked.latitude;
        _longitude = picked.longitude;
      });
    }
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_canSave) return;

    final tripId = widget.editing?.tripId ?? context.read<TripProvider>().current.trip.id;
    final provider = context.read<PlacesProvider>();
    final cost = double.tryParse(_costController.text.trim());

    final place = SavedPlace(
      id: widget.editing?.id ?? 'place-${DateTime.now().microsecondsSinceEpoch}',
      tripId: tripId,
      name: _nameController.text.trim(),
      latitude: _latitude!,
      longitude: _longitude!,
      category: _category!,
      area: _areaController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      priority: _priority,
      estimatedDuration: _duration,
      estimatedCost: cost,
      isFavorite: _isFavorite,
      photoUrl: widget.editing?.photoUrl ?? widget.draft?.photoUrl,
      googleMapsUrl: widget.editing?.googleMapsUrl ?? widget.draft?.googleMapsUrl,
      source: widget.editing?.source ?? widget.draft?.source ?? PlaceSource.manual,
    );

    if (_isEditing) {
      provider.updatePlace(place);
    } else {
      provider.addPlace(place);
    }
    Navigator.of(context).pop();
  }
}

class _CategoryButton extends StatelessWidget {
  final PlaceCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryButton({required this.category, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected
          ? category.color.withValues(alpha: 0.16)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? category.color : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(category.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text(
                category.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  fontSize: 10.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _durationOptions = <Duration?>[
  null,
  Duration(minutes: 30),
  Duration(hours: 1),
  Duration(hours: 2),
  Duration(hours: 3),
  Duration(hours: 4),
  Duration(hours: 8),
];

class _DurationChips extends StatelessWidget {
  final Duration? value;
  final ValueChanged<Duration?> onChanged;

  const _DurationChips({required this.value, required this.onChanged});

  String _label(Duration? d) {
    if (d == null) return 'None';
    if (d.inHours >= 8) return 'Full day';
    if (d.inHours >= 4) return 'Half day';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    final hours = d.inHours;
    return '${hours}h';
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in _durationOptions)
          ChoiceChip(
            label: Text(_label(option)),
            selected: value == option,
            onSelected: (_) => onChanged(option),
          ),
      ],
    );
  }
}

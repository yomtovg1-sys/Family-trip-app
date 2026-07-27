import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/trip.dart';
import '../providers/trip_provider.dart';

String tripChipLabel(Trip trip) =>
    '${trip.flagEmoji} ${trip.destination.split(',').last.trim()} ${trip.startDate.year}';

class TripSelector extends StatelessWidget {
  const TripSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripProvider>();
    final trip = provider.current.trip;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _openTripSheet(context),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tripChipLabel(trip), style: theme.textTheme.titleSmall),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  void _openTripSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _TripSheet(),
    );
  }
}

class _TripSheet extends StatelessWidget {
  const _TripSheet();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripProvider>();
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

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
            Text('Your Trips', style: theme.textTheme.titleLarge),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: provider.all.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final dashboard = provider.all[index];
                  final trip = dashboard.trip;
                  final isSelected = trip.id == provider.current.trip.id;
                  final status = trip.hasEnded
                      ? 'Completed'
                      : trip.hasStarted
                          ? 'In progress'
                          : 'Upcoming';

                  return Material(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        context.read<TripProvider>().selectTrip(trip.id);
                        Navigator.of(context).pop();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Text(trip.flagEmoji, style: const TextStyle(fontSize: 26)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    trip.name,
                                    style: theme.textTheme.titleSmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${dateFormat.format(trip.startDate)} · $status',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _openAddTripDialog(context);
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add New Trip'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddTripDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const _AddTripDialog());
  }
}

class _AddTripDialog extends StatefulWidget {
  const _AddTripDialog();

  @override
  State<_AddTripDialog> createState() => _AddTripDialogState();
}

class _AddTripDialogState extends State<_AddTripDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();
  final _flagController = TextEditingController(text: '🌍');
  DateTime _startDate = DateTime.now().add(const Duration(days: 30));
  DateTime _endDate = DateTime.now().add(const Duration(days: 37));

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    _flagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return AlertDialog(
      title: const Text('New Trip'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Trip name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _destinationController,
                decoration: const InputDecoration(labelText: 'Destination'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _flagController,
                decoration: const InputDecoration(labelText: 'Flag emoji'),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 8),
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              context.read<TripProvider>().addTrip(
                    name: _nameController.text.trim(),
                    destination: _destinationController.text.trim(),
                    flagEmoji: _flagController.text.trim().isEmpty
                        ? '🌍'
                        : _flagController.text.trim(),
                    startDate: _startDate,
                    endDate: _endDate,
                  );
              Navigator.of(context).pop();
            }
          },
          child: const Text('Create Trip'),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(vertical: 8),
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

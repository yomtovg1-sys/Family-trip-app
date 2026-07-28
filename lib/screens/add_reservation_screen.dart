import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/reservation.dart';
import '../models/reservation_draft.dart';
import '../models/travel_document.dart';
import '../providers/reservations_provider.dart';
import '../providers/trip_provider.dart';
import '../widgets/documents/add_document_sheet.dart';
import '../widgets/documents/document_card.dart';
import 'document_viewer_screen.dart';

class AddReservationScreen extends StatefulWidget {
  final ReservationCategory? category;
  final TravelDocument? initialAttachment;
  final ReservationDraft? draft;
  final Reservation? editing;

  const AddReservationScreen({
    super.key,
    this.category,
    this.initialAttachment,
    this.draft,
    this.editing,
  });

  @override
  State<AddReservationScreen> createState() => _AddReservationScreenState();
}

class _AddReservationScreenState extends State<AddReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  late ReservationCategory _category;
  late ReservationStatus _status;
  late DateTime _date;
  late TimeOfDay _time;
  late List<TravelDocument> _attachments;

  late final TextEditingController _titleController;
  late final TextEditingController _subtypeController;
  late final TextEditingController _locationController;
  late final TextEditingController _confirmationController;
  late final TextEditingController _providerController;
  late final TextEditingController _phoneController;
  late final TextEditingController _websiteController;
  late final TextEditingController _notesController;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    final draft = widget.draft;

    _category = editing?.category ?? draft?.category ?? widget.category ?? ReservationCategory.other;
    _status = editing?.status ?? ReservationStatus.upcoming;
    final initialDateTime = editing?.dateTime ?? draft?.dateTime ?? DateTime.now().add(const Duration(days: 1));
    _date = DateTime(initialDateTime.year, initialDateTime.month, initialDateTime.day);
    _time = TimeOfDay.fromDateTime(initialDateTime);
    _attachments = [
      ...?editing?.attachments,
      if (widget.initialAttachment != null) widget.initialAttachment!,
    ];

    _titleController = TextEditingController(text: editing?.title ?? draft?.title ?? '');
    _subtypeController = TextEditingController(text: editing?.subtype ?? '');
    _locationController = TextEditingController(text: editing?.location ?? draft?.location ?? '');
    _confirmationController =
        TextEditingController(text: editing?.confirmationNumber ?? draft?.confirmationNumber ?? '');
    _providerController = TextEditingController(text: editing?.provider ?? draft?.provider ?? '');
    _phoneController = TextEditingController(text: editing?.phone ?? '');
    _websiteController = TextEditingController(text: editing?.website ?? '');
    _notesController = TextEditingController(text: editing?.notes ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtypeController.dispose();
    _locationController.dispose();
    _confirmationController.dispose();
    _providerController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Reservation' : 'New Reservation')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            if (widget.initialAttachment != null && !_isEditing)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Theme.of(context).colorScheme.primary, size: 18),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "We'll be able to auto-fill these details from your document soon. "
                        'For now, please review and complete the fields below.',
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            Text('Type', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in ReservationCategory.values)
                  ChoiceChip(
                    label: Text('${category.emoji} ${category.singularLabel}'),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _subtypeController,
              decoration: const InputDecoration(
                labelText: 'Subtype (optional)',
                hintText: 'e.g. Rental Car, Train, Museum, Tour',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date'),
                      child: Text(dateFormat.format(_date)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Time'),
                      child: Text(_time.format(context)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmationController,
              decoration: const InputDecoration(labelText: 'Confirmation number'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _providerController,
              decoration: const InputDecoration(labelText: 'Provider'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone (optional)'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(labelText: 'Website (optional)'),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Text('Status', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final status in ReservationStatus.values)
                  ChoiceChip(
                    label: Text(status.label),
                    selected: _status == status,
                    onSelected: (_) => setState(() => _status = status),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Documents', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final document in _attachments)
                  DocumentCard(
                    document: document,
                    onPreview: () => _previewDocument(document),
                    onRename: (newName) => setState(() {
                      final index = _attachments.indexOf(document);
                      _attachments[index] = document.copyWith(fileName: newName);
                    }),
                    onShare: () => _shareDocument(document),
                    onDownload: () => _shareDocument(document),
                    onDelete: () => setState(() => _attachments.remove(document)),
                  ),
                AddDocumentTile(onTap: _addAttachments),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: Text(_isEditing ? 'Save Changes' : 'Add Reservation'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _addAttachments() async {
    await showAddDocumentSheet(
      context,
      onPicked: (documents) => setState(() => _attachments.addAll(documents)),
    );
  }

  void _previewDocument(TravelDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentViewerScreen(
          document: document,
          onRename: (newName) => setState(() {
            final index = _attachments.indexOf(document);
            _attachments[index] = document.copyWith(fileName: newName);
          }),
          onDelete: () => setState(() => _attachments.remove(document)),
        ),
      ),
    );
  }

  Future<void> _shareDocument(TravelDocument document) async {
    await Share.shareXFiles([XFile.fromData(document.bytes, name: document.fileName)]);
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final dateTime = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    final tripId = widget.editing?.tripId ?? context.read<TripProvider>().current.trip.id;
    final provider = context.read<ReservationsProvider>();

    final reservation = Reservation(
      id: widget.editing?.id ?? 'res-${DateTime.now().microsecondsSinceEpoch}',
      tripId: tripId,
      category: _category,
      subtype: _subtypeController.text.trim().isEmpty ? null : _subtypeController.text.trim(),
      title: _titleController.text.trim(),
      dateTime: dateTime,
      endDateTime: widget.editing?.endDateTime,
      location: _locationController.text.trim(),
      confirmationNumber: _confirmationController.text.trim(),
      provider: _providerController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      status: _status,
      attachments: _attachments,
    );

    if (_isEditing) {
      provider.updateReservation(reservation);
    } else {
      provider.addReservation(reservation);
    }
    Navigator.of(context).pop();
  }
}

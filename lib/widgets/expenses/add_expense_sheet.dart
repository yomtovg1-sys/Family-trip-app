import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expense_draft.dart';
import '../../models/expense_entry.dart';
import '../../models/travel_document.dart';
import '../../services/expense_extractor.dart';
import '../../utils/currency.dart';
import '../documents/add_document_sheet.dart';
import '../emoji_text.dart';
import '../image_or_placeholder.dart';

/// The "Add Expense" bottom sheet. Built for speed: amount + category is
/// enough to save, everything else is optional. Attaching a receipt runs it
/// through [ExpenseExtractor] and the sheet switches into a review state —
/// pre-filled fields the family can still edit before saving.
Future<void> showAddExpenseSheet(
  BuildContext context, {
  required String tripCurrency,
  required void Function(ExpenseEntry expense) onSave,
  ExpenseExtractor extractor = const MockExpenseExtractor(),
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => AddExpenseSheet(
      tripCurrency: tripCurrency,
      onSave: onSave,
      extractor: extractor,
    ),
  );
}

class AddExpenseSheet extends StatefulWidget {
  final String tripCurrency;
  final void Function(ExpenseEntry expense) onSave;
  final ExpenseExtractor extractor;

  const AddExpenseSheet({
    super.key,
    required this.tripCurrency,
    required this.onSave,
    this.extractor = const MockExpenseExtractor(),
  });

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _merchantController;
  late final TextEditingController _notesController;
  late String _currency;
  ExpenseCategory? _category;
  bool _categorySuggested = false;
  bool _showReceiptDetails = false;
  DateTime? _receiptDate;
  TravelDocument? _receipt;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _currency = widget.tripCurrency;
    _amountController = TextEditingController();
    _merchantController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _canSave => !_scanning && (double.tryParse(_amountController.text.trim()) ?? 0) > 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(28),
          ),
          child: SingleChildScrollView(
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
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: Text('Add Expense', style: theme.textTheme.titleLarge)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                if (_scanning) ...[
                  const SizedBox(height: 4),
                  _InfoBanner(
                    icon: Icons.auto_awesome_rounded,
                    text: 'Reading your receipt…',
                    showSpinner: true,
                  ),
                ] else if (_showReceiptDetails) ...[
                  const SizedBox(height: 4),
                  const _InfoBanner(
                    icon: Icons.fact_check_rounded,
                    text: 'Scanned from your receipt — review and save.',
                  ),
                ],
                if (_showReceiptDetails) ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: _merchantController,
                    decoration: const InputDecoration(labelText: 'Merchant'),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _amountController,
                        autofocus: !_showReceiptDetails,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixText: '${currencySymbol(_currency)} ',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _CurrencyField(
                        value: _currency,
                        onChanged: (v) => setState(() => _currency = v),
                      ),
                    ),
                  ],
                ),
                if (_showReceiptDetails) ...[
                  const SizedBox(height: 14),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date'),
                      child: Text(DateFormat('d MMM yyyy').format(_receiptDate ?? DateTime.now())),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    Text('Category', style: theme.textTheme.titleSmall),
                    if (_categorySuggested) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(Suggested)',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.6,
                  children: [
                    for (final category in ExpenseCategory.values)
                      _CategoryButton(
                        category: category,
                        selected: _category == category,
                        onTap: () => setState(() {
                          _category = category;
                          _categorySuggested = false;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                Text('Receipt', style: theme.textTheme.titleSmall),
                const SizedBox(height: 10),
                if (_receipt != null)
                  _ReceiptTile(document: _receipt!, onRemove: _removeReceipt)
                else
                  OutlinedButton.icon(
                    onPressed: _scanning ? null : _addReceipt,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('Add Receipt'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _canSave ? _save : null,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receiptDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _receiptDate = picked);
  }

  Future<void> _addReceipt() async {
    await showAddDocumentSheet(
      context,
      onPicked: (documents) async {
        if (documents.isEmpty) return;
        final document = documents.first;
        setState(() {
          _receipt = document;
          _scanning = true;
        });
        final draft = await widget.extractor.extract(document, tripCurrency: widget.tripCurrency);
        if (!mounted) return;
        setState(() {
          _scanning = false;
          _applyDraft(draft);
        });
      },
    );
  }

  void _removeReceipt() {
    setState(() {
      _receipt = null;
      _showReceiptDetails = false;
      _categorySuggested = false;
    });
  }

  void _applyDraft(ExpenseDraft draft) {
    _showReceiptDetails = true;
    if (draft.merchant != null) _merchantController.text = draft.merchant!;
    if (draft.amount != null) _amountController.text = draft.amount!.toStringAsFixed(0);
    if (draft.currency != null) _currency = draft.currency!;
    if (draft.suggestedCategory != null) {
      _category = draft.suggestedCategory;
      _categorySuggested = true;
    }
    if (draft.date != null) _receiptDate = draft.date;
  }

  void _save() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    final expense = ExpenseEntry(
      id: 'exp-${DateTime.now().microsecondsSinceEpoch}',
      amount: amount,
      currency: _currency,
      category: _category ?? ExpenseCategory.other,
      date: _receiptDate ?? DateTime.now(),
      merchant: _merchantController.text.trim().isEmpty ? null : _merchantController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      receipt: _receipt,
    );

    widget.onSave(expense);
    Navigator.of(context).pop();
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool showSpinner;

  const _InfoBanner({required this.icon, required this.text, this.showSpinner = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          if (showSpinner)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
            )
          else
            Icon(icon, color: theme.colorScheme.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5))),
        ],
      ),
    );
  }
}

class _CurrencyField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _CurrencyField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _pickCurrency(context),
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Currency'),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            const Icon(Icons.expand_more_rounded, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCurrency(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(sheetContext).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final code in supportedCurrencies)
                ChoiceChip(
                  label: Text('${currencySymbol(code)} $code'),
                  selected: code == value,
                  onSelected: (_) => Navigator.of(sheetContext).pop(code),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) onChanged(selected);
  }
}

class _CategoryButton extends StatelessWidget {
  final ExpenseCategory category;
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
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? category.color : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              EmojiText(category.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                category.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
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

class _ReceiptTile extends StatelessWidget {
  final TravelDocument document;
  final VoidCallback onRemove;

  const _ReceiptTile({required this.document, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 40,
              height: 40,
              child: document.type == AttachmentType.image
                  ? ImageOrPlaceholder(bytes: document.bytes, icon: document.type.icon, iconSize: 18)
                  : Container(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                      alignment: Alignment.center,
                      child: Icon(document.type.icon, size: 18, color: theme.colorScheme.primary),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              document.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/document_category.dart';
import '../models/vault_document.dart';
import '../services/personal_vault.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_section.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/documents/add_document_sheet.dart';
import '../widgets/documents/document_card.dart';
import '../widgets/empty_state.dart';
import 'document_viewer_screen.dart';

/// The subset of [DocumentCategory] values relevant to a permanent,
/// personal document — passports, licenses, insurance, and so on.
/// Flight/hotel/car-rental/ticket categories are reservation-specific and
/// don't apply to the vault.
const _vaultDocumentCategories = [
  DocumentCategory.passport,
  DocumentCategory.driverLicense,
  DocumentCategory.internationalDrivingPermit,
  DocumentCategory.insurance,
  DocumentCategory.frequentFlyer,
  DocumentCategory.loungeMembership,
  DocumentCategory.emergencyContact,
  DocumentCategory.visa,
  DocumentCategory.other,
];

/// The Personal Vault: permanent family documents — passports, licenses,
/// insurance cards — that live outside any single trip. Every document
/// here is uploaded once; trips only ever attach a reference to one of
/// these (see the "Attach from Vault" step when creating a trip in Trip
/// Manager), so editing or replacing a document here is instantly what
/// every trip sees.
class PersonalVaultScreen extends StatelessWidget {
  const PersonalVaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final documents = context.watch<PersonalVault>().documents;

    final byCategory = <DocumentCategory, List<VaultDocument>>{};
    for (final doc in documents) {
      byCategory.putIfAbsent(doc.category, () => []).add(doc);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add document',
            onPressed: () => _addDocument(context),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: AppSection.personalVaultRoute),
      body: documents.isEmpty
          ? EmptyState(
              visual: Icon(Icons.shield_rounded, size: 48, color: theme.colorScheme.outlineVariant),
              title: 'Your vault is empty',
              subtitle: 'Passports, licenses, insurance cards — upload them once here and '
                  'attach them to any trip.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "These documents aren't tied to any trip — upload once, reuse everywhere.",
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                for (final category in DocumentCategory.values)
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
                            document: document.asTravelDocument.copyWith(fileName: document.displayName),
                            onPreview: () => _openViewer(context, document),
                            onRename: (newName) =>
                                context.read<PersonalVault>().renameDocument(document.id, newName),
                            onShare: () => _shareFile(document),
                            onDownload: () => _shareFile(document),
                            onDelete: () => _confirmDelete(context, document),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
              ],
            ),
    );
  }

  void _openViewer(BuildContext context, VaultDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentViewerScreen(
          document: document.asTravelDocument.copyWith(fileName: document.displayName),
          onRename: (newName) => context.read<PersonalVault>().renameDocument(document.id, newName),
          onDelete: () => context.read<PersonalVault>().removeDocument(document.id),
        ),
      ),
    );
  }

  Future<void> _shareFile(VaultDocument document) async {
    await Share.shareXFiles([XFile.fromData(document.bytes, name: document.fileName)]);
  }

  Future<void> _confirmDelete(BuildContext context, VaultDocument document) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete this document?',
      message: '"${document.displayName}" will be removed from the vault. Any trip referencing it will no '
          'longer show it.',
      isDestructive: true,
    );
    if (confirmed && context.mounted) {
      context.read<PersonalVault>().removeDocument(document.id);
    }
  }

  Future<void> _addDocument(BuildContext context) async {
    final category = await showModalBottomSheet<DocumentCategory>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _VaultCategoryPickerSheet(),
    );
    if (category == null || !context.mounted) return;

    final vault = context.read<PersonalVault>();
    await showAddDocumentSheet(
      context,
      onPicked: (documents) async {
        for (final document in documents) {
          if (!context.mounted) return;
          final holderName = await _showHolderNameDialog(context);
          if (holderName == null || holderName.trim().isEmpty) continue;
          vault.addDocument(
            VaultDocument(
              id: 'vault-${DateTime.now().microsecondsSinceEpoch}',
              holderName: holderName.trim(),
              category: category,
              fileName: document.fileName,
              type: document.type,
              bytes: document.bytes,
              uploadedAt: DateTime.now(),
            ),
          );
        }
      },
    );
  }

  Future<String?> _showHolderNameDialog(BuildContext context) {
    final controller = TextEditingController();
    const suggestions = ['Galit', 'Amit', 'Family'];

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Whose document is this?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final name in suggestions)
                  ActionChip(label: Text(name), onPressed: () => controller.text = name),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _VaultCategoryPickerSheet extends StatelessWidget {
  const _VaultCategoryPickerSheet();

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
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final category in _vaultDocumentCategories)
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
          ],
        ),
      ),
    );
  }
}

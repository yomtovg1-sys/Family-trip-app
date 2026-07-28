import 'package:flutter/material.dart';

/// The "+" chooser sheet: every way to add a place to the trip.
Future<void> showAddPlaceSheet(
  BuildContext context, {
  required VoidCallback onSearch,
  required VoidCallback onPasteUrl,
  required VoidCallback onScanScreenshot,
  required VoidCallback onPasteWebsite,
  required VoidCallback onManualEntry,
  required VoidCallback onImportFromGoogleMaps,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => _AddPlaceSheet(
      onSearch: onSearch,
      onPasteUrl: onPasteUrl,
      onScanScreenshot: onScanScreenshot,
      onPasteWebsite: onPasteWebsite,
      onManualEntry: onManualEntry,
      onImportFromGoogleMaps: onImportFromGoogleMaps,
    ),
  );
}

class _AddPlaceSheet extends StatelessWidget {
  final VoidCallback onSearch;
  final VoidCallback onPasteUrl;
  final VoidCallback onScanScreenshot;
  final VoidCallback onPasteWebsite;
  final VoidCallback onManualEntry;
  final VoidCallback onImportFromGoogleMaps;

  const _AddPlaceSheet({
    required this.onSearch,
    required this.onPasteUrl,
    required this.onScanScreenshot,
    required this.onPasteWebsite,
    required this.onManualEntry,
    required this.onImportFromGoogleMaps,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
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
              const SizedBox(height: 18),
              Text('Add a Place', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Choose how you\'d like to save it',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              _OptionTile(
                emoji: '🔎',
                title: 'Google Maps search',
                subtitle: 'Find a place by name',
                onTap: () {
                  Navigator.of(context).pop();
                  onSearch();
                },
              ),
              _OptionTile(
                emoji: '🔗',
                title: 'Paste Google Maps URL',
                subtitle: 'Share a link from the Google Maps app',
                onTap: () {
                  Navigator.of(context).pop();
                  onPasteUrl();
                },
              ),
              _OptionTile(
                emoji: '📸',
                title: 'Scan screenshot',
                subtitle: 'AI-read a place card screenshot (coming soon)',
                onTap: () {
                  Navigator.of(context).pop();
                  onScanScreenshot();
                },
              ),
              _OptionTile(
                emoji: '🌐',
                title: 'Paste website',
                subtitle: 'Add from a restaurant or hotel website',
                onTap: () {
                  Navigator.of(context).pop();
                  onPasteWebsite();
                },
              ),
              _OptionTile(
                emoji: '✍️',
                title: 'Manual entry',
                subtitle: 'Type in the details yourself',
                onTap: () {
                  Navigator.of(context).pop();
                  onManualEntry();
                },
              ),
              const Divider(height: 20),
              _OptionTile(
                emoji: '📥',
                title: 'Import from Google Maps',
                subtitle: 'Bring in your saved lists all at once',
                onTap: () {
                  Navigator.of(context).pop();
                  onImportFromGoogleMaps();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

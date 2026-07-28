import 'package:flutter/material.dart';

/// The minimal "+" chooser for the Places screen: three quick ways to add a
/// place, kept short on purpose (the richer Map screen has its own chooser
/// with more capture methods).
Future<void> showSimpleAddPlaceSheet(
  BuildContext context, {
  required VoidCallback onAddManually,
  required VoidCallback onPickFromMap,
  required VoidCallback onSearch,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _SimpleAddPlaceSheet(
      onAddManually: onAddManually,
      onPickFromMap: onPickFromMap,
      onSearch: onSearch,
    ),
  );
}

class _SimpleAddPlaceSheet extends StatelessWidget {
  final VoidCallback onAddManually;
  final VoidCallback onPickFromMap;
  final VoidCallback onSearch;

  const _SimpleAddPlaceSheet({
    required this.onAddManually,
    required this.onPickFromMap,
    required this.onSearch,
  });

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
            Text('Add a Place', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            _OptionTile(
              icon: Icons.edit_note_rounded,
              title: 'Add manually',
              subtitle: 'Type in the name and details',
              onTap: () {
                Navigator.of(context).pop();
                onAddManually();
              },
            ),
            _OptionTile(
              icon: Icons.map_rounded,
              title: 'Save from map',
              subtitle: 'Drop a pin on the map to save it',
              onTap: () {
                Navigator.of(context).pop();
                onPickFromMap();
              },
            ),
            _OptionTile(
              icon: Icons.search_rounded,
              title: 'Search for a place',
              subtitle: 'Find it by name',
              onTap: () {
                Navigator.of(context).pop();
                onSearch();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
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
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

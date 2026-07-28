import 'package:flutter/material.dart';
import '../../models/place.dart';

/// The "All • Attractions • Nature • Food • Hotels • Shopping • Favorites"
/// filter row shown above the map.
class PlaceFilterChips extends StatelessWidget {
  final PlaceFilter selected;
  final ValueChanged<PlaceFilter> onSelected;

  const PlaceFilterChips({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: PlaceFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = PlaceFilter.values[index];
          return _FilterChip(
            filter: filter,
            selected: selected == filter,
            onTap: () => onSelected(filter),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final PlaceFilter filter;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.filter, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Material(
      color: selected ? color : theme.colorScheme.surface,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? color : theme.colorScheme.outlineVariant),
      ),
      elevation: selected ? 2 : 0,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            filter == PlaceFilter.favorites ? '★ ${filter.label}' : filter.label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

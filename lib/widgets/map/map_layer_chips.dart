import 'package:flutter/material.dart';
import '../../models/map_pin.dart';

/// The multi-select layer toggle row shown above the map — every layer is
/// independently on or off, unlike [PlaceFilterChips] on the Places list
/// screen (single-select, browsing one category at a time).
class MapLayerChips extends StatelessWidget {
  final Set<MapLayer> enabled;
  final ValueChanged<MapLayer> onToggle;

  const MapLayerChips({super.key, required this.enabled, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: MapLayer.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final layer = MapLayer.values[index];
          return _LayerChip(
            layer: layer,
            selected: enabled.contains(layer),
            onTap: () => onToggle(layer),
          );
        },
      ),
    );
  }
}

class _LayerChip extends StatelessWidget {
  final MapLayer layer;
  final bool selected;
  final VoidCallback onTap;

  const _LayerChip({required this.layer, required this.selected, required this.onTap});

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                layer.icon,
                size: 16,
                color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                layer.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

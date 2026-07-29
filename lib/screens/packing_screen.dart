import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/packing_provider.dart';
import '../providers/trip_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_section.dart';
import '../widgets/empty_state.dart';

class PackingScreen extends StatelessWidget {
  const PackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tripId = context.watch<TripProvider>().current.trip.id;
    final items = context.watch<PackingProvider>().forTrip(tripId);
    final packedCount = items.where((i) => i.isPacked).length;
    final progress = items.isEmpty ? 0.0 : packedCount / items.length;

    final byCategory = <String, List<int>>{};
    for (var i = 0; i < items.length; i++) {
      byCategory.putIfAbsent(items[i].category, () => []).add(i);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Packing Checklist')),
      drawer: const AppDrawer(currentRoute: AppSection.packingRoute),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                LinearProgressIndicator(value: progress, minHeight: 8),
                const SizedBox(height: 8),
                Text('$packedCount of ${items.length} items packed'),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const EmptyState(
                    visual: Text('🧳', style: TextStyle(fontSize: 44)),
                    title: 'Nothing to pack yet',
                    subtitle: 'Packing items for this trip will show up here.',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    children: [
                      for (final category in byCategory.keys)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                              child: Text(
                                category,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                            for (final index in byCategory[category]!)
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: CheckboxListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  value: items[index].isPacked,
                                  title: Text(items[index].name),
                                  subtitle: Text('Assigned to ${items[index].assignedTo}'),
                                  onChanged: (_) => context
                                      .read<PackingProvider>()
                                      .togglePacked(items[index].id),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

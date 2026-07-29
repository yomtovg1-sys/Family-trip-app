import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/packing_provider.dart';
import '../providers/trip_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_section.dart';

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
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No packing items for this trip yet.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  )
                : ListView(
                    children: [
                      for (final category in byCategory.keys)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Text(
                                category,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                            for (final index in byCategory[category]!)
                              CheckboxListTile(
                                value: items[index].isPacked,
                                title: Text(items[index].name),
                                subtitle: Text('Assigned to ${items[index].assignedTo}'),
                                onChanged: (_) =>
                                    context.read<PackingProvider>().togglePacked(items[index].id),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/packing_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_section.dart';

class PackingScreen extends StatelessWidget {
  const PackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final packing = context.watch<PackingProvider>();
    final byCategory = <String, List<int>>{};
    for (var i = 0; i < packing.items.length; i++) {
      byCategory.putIfAbsent(packing.items[i].category, () => []).add(i);
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
                LinearProgressIndicator(value: packing.progress, minHeight: 8),
                const SizedBox(height: 8),
                Text('${packing.packedCount} of ${packing.items.length} items packed'),
              ],
            ),
          ),
          Expanded(
            child: ListView(
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
                                color: Colors.grey[600],
                              ),
                        ),
                      ),
                      for (final index in byCategory[category]!)
                        CheckboxListTile(
                          value: packing.items[index].isPacked,
                          title: Text(packing.items[index].name),
                          subtitle: Text('Assigned to ${packing.items[index].assignedTo}'),
                          onChanged: (_) => packing.togglePacked(packing.items[index].id),
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

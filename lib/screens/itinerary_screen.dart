import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/itinerary_item.dart';
import '../providers/itinerary_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_section.dart';

class ItineraryScreen extends StatelessWidget {
  const ItineraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final days = context.watch<ItineraryProvider>().days;
    final dateFormat = DateFormat('EEEE, MMM d');

    return DefaultTabController(
      length: days.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Daily Itinerary'),
          bottom: TabBar(
            isScrollable: true,
            tabs: [for (final day in days) Tab(text: 'Day ${days.indexOf(day) + 1}')],
          ),
        ),
        drawer: const AppDrawer(currentRoute: AppSection.itineraryRoute),
        body: TabBarView(
          children: [
            for (final day in days)
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    day.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    dateFormat.format(day.date),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  for (final item in day.items) _ItineraryTile(item: item),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ItineraryTile extends StatelessWidget {
  final ItineraryItem item;

  const _ItineraryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(item.category.icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${item.time.format(context)} · ${item.location}'),
        trailing: Text(item.category.label, style: Theme.of(context).textTheme.labelSmall),
      ),
    );
  }
}

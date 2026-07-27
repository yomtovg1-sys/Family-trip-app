import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/reservation.dart';
import '../providers/reservations_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_section.dart';

class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reservations = context.watch<ReservationsProvider>().reservations;
    final dateFormat = DateFormat('MMM d, h:mm a');

    return Scaffold(
      appBar: AppBar(title: const Text('Reservations')),
      drawer: const AppDrawer(currentRoute: AppSection.reservationsRoute),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reservations.length,
        itemBuilder: (context, index) {
          final r = reservations[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(r.type.icon, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      Chip(label: Text(r.type.label), visualDensity: VisualDensity.compact),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Confirmation #${r.confirmationNumber}'),
                  const SizedBox(height: 4),
                  Text(
                    r.end != null
                        ? '${dateFormat.format(r.start)} → ${dateFormat.format(r.end!)}'
                        : dateFormat.format(r.start),
                  ),
                  const SizedBox(height: 4),
                  Text(r.details, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import 'app_section.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripProvider>().trip;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/family_hero.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(trip.heroEmoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  Text(
                    trip.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    trip.destination,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            for (final section in AppSection.all)
              ListTile(
                leading: Icon(section.icon, color: section.color),
                title: Text(section.title),
                selected: section.route == currentRoute,
                onTap: () {
                  Navigator.of(context).pop();
                  if (section.route != currentRoute) {
                    Navigator.of(context).pushReplacementNamed(section.route);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

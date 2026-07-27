import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/itinerary_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_section.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final days = context.watch<ItineraryProvider>().days;
    final stops = <_MapStop>[
      for (final day in days)
        for (final item in day.items)
          if (item.latitude != null && item.longitude != null)
            _MapStop(title: item.title, point: LatLng(item.latitude!, item.longitude!)),
    ];

    final center = stops.isNotEmpty
        ? stops[0].point
        : const LatLng(39.0968, -120.0324);

    return Scaffold(
      appBar: AppBar(title: const Text('Trip Map')),
      drawer: const AppDrawer(currentRoute: AppSection.mapRoute),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 10,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.familytrip.family_trip_app',
              ),
              MarkerLayer(
                markers: [
                  for (var i = 0; i < stops.length; i++)
                    Marker(
                      point: stops[i].point,
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedIndex = i),
                        child: Icon(
                          Icons.location_on,
                          color: _selectedIndex == i
                              ? Colors.red
                              : Theme.of(context).colorScheme.primary,
                          size: 40,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (_selectedIndex != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.place),
                  title: Text(stops[_selectedIndex!].title),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selectedIndex = null),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapStop {
  final String title;
  final LatLng point;

  const _MapStop({required this.title, required this.point});
}

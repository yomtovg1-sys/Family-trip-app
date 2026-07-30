import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// A full-screen map for picking a coordinate by panning a fixed center
/// crosshair over the spot you want — the manual-entry equivalent of
/// dropping a pin, without needing to type raw latitude/longitude.
class PickLocationScreen extends StatefulWidget {
  final LatLng initialCenter;

  const PickLocationScreen({super.key, required this.initialCenter});

  @override
  State<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends State<PickLocationScreen> {
  late final MapController _mapController;
  late LatLng _center;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _center = widget.initialCenter;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Location')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) setState(() => _center = position.center);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.familytrip.family_trip_app',
              ),
            ],
          ),
          IgnorePointer(
            child: Transform.translate(
              offset: const Offset(0, -22),
              child: Icon(Icons.location_on_rounded, size: 44, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_center),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Text(
                  'Use this location (${_center.latitude.toStringAsFixed(4)}, ${_center.longitude.toStringAsFixed(4)})',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

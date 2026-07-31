import 'package:flutter/material.dart';
import 'place.dart';

/// A packing item a template suggests. [assignedTo] is a sensible default
/// ("Everyone" unless the template knows better) — applying the template
/// just seeds the trip's packing list, nothing is locked in.
class TemplatePackingItem {
  final String name;
  final String category;
  final String assignedTo;

  const TemplatePackingItem({
    required this.name,
    required this.category,
    this.assignedTo = 'Everyone',
  });
}

/// A suggested place a template can seed into a trip's Explore list.
/// Coordinates are optional — a template built around a well-known
/// destination (like Japan) can ship real, mappable suggestions; a more
/// generic template (like Road Trip) can suggest categories of places to
/// look for without pretending to know exact coordinates.
class TemplatePlace {
  final String name;
  final PlaceCategory category;
  final String area;
  final double? latitude;
  final double? longitude;
  final String? notes;

  const TemplatePlace({
    required this.name,
    required this.category,
    required this.area,
    this.latitude,
    this.longitude,
    this.notes,
  });

  bool get hasCoordinates => latitude != null && longitude != null;
}

/// A reusable starting point for a new trip — packing list, favorite
/// places, a travel checklist, and freeform notes — that
/// [TripManager.applyTemplate] copies into a trip's own providers. Applying
/// a template never touches the Personal Vault; it only seeds
/// trip-scoped data.
class TripTemplate {
  final String id;
  final String name;
  final IconData icon;
  final String description;
  final List<TemplatePackingItem> packingItems;
  final List<TemplatePlace> favoritePlaces;
  final List<String> checklist;
  final List<String> notes;

  const TripTemplate({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    this.packingItems = const [],
    this.favoritePlaces = const [],
    this.checklist = const [],
    this.notes = const [],
  });
}

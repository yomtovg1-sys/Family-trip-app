import 'package:flutter/material.dart';
import 'place.dart';
import 'reservation.dart';

/// The toggleable layers shown on the Map screen. Deliberately coarser
/// than [PlaceCategory]/[ReservationCategory] — several real categories
/// collapse into the same layer (restaurants + cafes both count as
/// "Restaurants"; every non-hotel reservation is just "Reservations").
enum MapLayer { hotels, activities, restaurants, reservations, personalPlaces }

extension MapLayerX on MapLayer {
  String get label {
    switch (this) {
      case MapLayer.hotels:
        return 'Hotels';
      case MapLayer.activities:
        return 'Activities';
      case MapLayer.restaurants:
        return 'Restaurants';
      case MapLayer.reservations:
        return 'Reservations';
      case MapLayer.personalPlaces:
        return 'Saved Places';
    }
  }

  IconData get icon {
    switch (this) {
      case MapLayer.hotels:
        return Icons.hotel_rounded;
      case MapLayer.activities:
        return Icons.hiking_rounded;
      case MapLayer.restaurants:
        return Icons.restaurant_rounded;
      case MapLayer.reservations:
        return Icons.confirmation_number_rounded;
      case MapLayer.personalPlaces:
        return Icons.bookmark_rounded;
    }
  }
}

/// A single pin on the Map screen — a rendering-only view over whatever
/// actually produced it. Today that's always a [SavedPlace] or a
/// [Reservation] with coordinates set, but the map-rendering code only
/// ever looks at this type, not those — so a future Google Places result
/// (or any other source) can add a third `MapPin.fromX` factory without
/// touching the map screen or its widgets at all.
class MapPin {
  final String id;
  final String title;
  final String subtitle;
  final double latitude;
  final double longitude;
  final String emoji;
  final Color color;
  final MapLayer layer;
  final SavedPlace? place;
  final Reservation? reservation;

  const MapPin({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
    required this.emoji,
    required this.color,
    required this.layer,
    this.place,
    this.reservation,
  });

  factory MapPin.fromPlace(SavedPlace place) {
    final layer = switch (place.category) {
      PlaceCategory.hotels => MapLayer.hotels,
      PlaceCategory.attractions || PlaceCategory.nature => MapLayer.activities,
      PlaceCategory.restaurants || PlaceCategory.cafes => MapLayer.restaurants,
      PlaceCategory.shopping || PlaceCategory.parking || PlaceCategory.other => MapLayer.personalPlaces,
    };
    return MapPin(
      id: 'place-${place.id}',
      title: place.name,
      subtitle: place.area,
      latitude: place.latitude,
      longitude: place.longitude,
      emoji: place.category.emoji,
      color: place.category.color,
      layer: layer,
      place: place,
    );
  }

  /// Only call this for a reservation that has [Reservation.hasCoordinates]
  /// — a reservation with no pinned location has nothing to render here.
  factory MapPin.fromReservation(Reservation reservation) {
    final layer = reservation.category == ReservationCategory.hotel ? MapLayer.hotels : MapLayer.reservations;
    return MapPin(
      id: 'reservation-${reservation.id}',
      title: reservation.title,
      subtitle: reservation.location,
      latitude: reservation.latitude!,
      longitude: reservation.longitude!,
      emoji: reservation.category.emoji,
      color: reservation.category.color,
      layer: layer,
      reservation: reservation,
    );
  }
}

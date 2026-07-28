import 'package:flutter/material.dart';

enum PlaceCategory {
  attractions,
  nature,
  restaurants,
  cafes,
  hotels,
  shopping,
  parking,
  other,
}

extension PlaceCategoryX on PlaceCategory {
  String get emoji {
    switch (this) {
      case PlaceCategory.attractions:
        return '🎟️';
      case PlaceCategory.nature:
        return '🌲';
      case PlaceCategory.restaurants:
        return '🍽️';
      case PlaceCategory.cafes:
        return '☕';
      case PlaceCategory.hotels:
        return '🏨';
      case PlaceCategory.shopping:
        return '🛍️';
      case PlaceCategory.parking:
        return '🅿️';
      case PlaceCategory.other:
        return '📍';
    }
  }

  String get label {
    switch (this) {
      case PlaceCategory.attractions:
        return 'Attractions';
      case PlaceCategory.nature:
        return 'Nature';
      case PlaceCategory.restaurants:
        return 'Restaurants';
      case PlaceCategory.cafes:
        return 'Cafes';
      case PlaceCategory.hotels:
        return 'Hotels';
      case PlaceCategory.shopping:
        return 'Shopping';
      case PlaceCategory.parking:
        return 'Parking';
      case PlaceCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case PlaceCategory.attractions:
        return Icons.attractions_rounded;
      case PlaceCategory.nature:
        return Icons.park_rounded;
      case PlaceCategory.restaurants:
        return Icons.restaurant_rounded;
      case PlaceCategory.cafes:
        return Icons.local_cafe_rounded;
      case PlaceCategory.hotels:
        return Icons.hotel_rounded;
      case PlaceCategory.shopping:
        return Icons.shopping_bag_rounded;
      case PlaceCategory.parking:
        return Icons.local_parking_rounded;
      case PlaceCategory.other:
        return Icons.place_rounded;
    }
  }

  Color get color {
    switch (this) {
      case PlaceCategory.attractions:
        return const Color(0xFFFFC94D);
      case PlaceCategory.nature:
        return const Color(0xFF2F9E44);
      case PlaceCategory.restaurants:
        return const Color(0xFFFF8A65);
      case PlaceCategory.cafes:
        return const Color(0xFF8D6E63);
      case PlaceCategory.hotels:
        return const Color(0xFF7986CB);
      case PlaceCategory.shopping:
        return const Color(0xFFBA68C8);
      case PlaceCategory.parking:
        return const Color(0xFF546E7A);
      case PlaceCategory.other:
        return const Color(0xFF90A4AE);
    }
  }
}

/// The top-level filter chips shown above the map: broader than
/// [PlaceCategory] (Food groups Restaurants + Cafes) and adds an "All" and
/// a "Favorites" pseudo-filter that aren't categories at all.
enum PlaceFilter { all, attractions, nature, food, hotels, shopping, favorites }

extension PlaceFilterX on PlaceFilter {
  String get label {
    switch (this) {
      case PlaceFilter.all:
        return 'All';
      case PlaceFilter.attractions:
        return 'Attractions';
      case PlaceFilter.nature:
        return 'Nature';
      case PlaceFilter.food:
        return 'Food';
      case PlaceFilter.hotels:
        return 'Hotels';
      case PlaceFilter.shopping:
        return 'Shopping';
      case PlaceFilter.favorites:
        return 'Favorites';
    }
  }

  bool matches(SavedPlace place) {
    switch (this) {
      case PlaceFilter.all:
        return true;
      case PlaceFilter.attractions:
        return place.category == PlaceCategory.attractions;
      case PlaceFilter.nature:
        return place.category == PlaceCategory.nature;
      case PlaceFilter.food:
        return place.category == PlaceCategory.restaurants || place.category == PlaceCategory.cafes;
      case PlaceFilter.hotels:
        return place.category == PlaceCategory.hotels;
      case PlaceFilter.shopping:
        return place.category == PlaceCategory.shopping;
      case PlaceFilter.favorites:
        return place.isFavorite;
    }
  }
}

/// How a [SavedPlace] made it into the trip — purely informational (shown
/// nowhere critical yet) but useful for debugging import flows later.
enum PlaceSource { manual, googleSearch, googleMapsUrl, screenshot, website, googleImport }

/// A place the family has saved for the trip: a restaurant to try, a
/// viewpoint, a hotel they're considering, a parking garage near the venue.
/// This is a planning record, not a live map/navigation entity.
class SavedPlace {
  final String id;
  final String tripId;
  final String name;
  final double latitude;
  final double longitude;
  final PlaceCategory category;
  final String area;
  final String? notes;
  final bool isFavorite;
  final String? googleMapsUrl;
  final PlaceSource source;

  const SavedPlace({
    required this.id,
    required this.tripId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.area,
    this.notes,
    this.isFavorite = false,
    this.googleMapsUrl,
    this.source = PlaceSource.manual,
  });

  SavedPlace copyWith({
    String? name,
    double? latitude,
    double? longitude,
    PlaceCategory? category,
    String? area,
    String? notes,
    bool? isFavorite,
    String? googleMapsUrl,
    PlaceSource? source,
  }) {
    return SavedPlace(
      id: id,
      tripId: tripId,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      area: area ?? this.area,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      googleMapsUrl: googleMapsUrl ?? this.googleMapsUrl,
      source: source ?? this.source,
    );
  }

  /// A Google Maps deep link built from the exact coordinates, used any
  /// time we don't already have a real share URL (e.g. manual entries).
  String get mapsSearchUrl =>
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
}

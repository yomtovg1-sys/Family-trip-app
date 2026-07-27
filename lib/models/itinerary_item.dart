import 'package:flutter/material.dart';

enum ItineraryCategory { travel, food, activity, lodging, other }

extension ItineraryCategoryX on ItineraryCategory {
  IconData get icon {
    switch (this) {
      case ItineraryCategory.travel:
        return Icons.directions_car_filled;
      case ItineraryCategory.food:
        return Icons.restaurant;
      case ItineraryCategory.activity:
        return Icons.hiking;
      case ItineraryCategory.lodging:
        return Icons.hotel;
      case ItineraryCategory.other:
        return Icons.star;
    }
  }

  String get label {
    switch (this) {
      case ItineraryCategory.travel:
        return 'Travel';
      case ItineraryCategory.food:
        return 'Food';
      case ItineraryCategory.activity:
        return 'Activity';
      case ItineraryCategory.lodging:
        return 'Lodging';
      case ItineraryCategory.other:
        return 'Other';
    }
  }
}

class ItineraryItem {
  final String title;
  final TimeOfDay time;
  final String location;
  final ItineraryCategory category;
  final String? notes;
  final double? latitude;
  final double? longitude;

  const ItineraryItem({
    required this.title,
    required this.time,
    required this.location,
    required this.category,
    this.notes,
    this.latitude,
    this.longitude,
  });
}

class ItineraryDay {
  final DateTime date;
  final String title;
  final List<ItineraryItem> items;

  const ItineraryDay({
    required this.date,
    required this.title,
    required this.items,
  });
}

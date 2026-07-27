import 'package:flutter/material.dart';
import '../models/itinerary_item.dart';

class ItineraryProvider extends ChangeNotifier {
  final List<ItineraryDay> _days = [
    ItineraryDay(
      date: DateTime.now().add(const Duration(days: 21)),
      title: 'Arrival Day',
      items: [
        ItineraryItem(
          title: 'Flight to Reno-Tahoe Airport',
          time: const TimeOfDay(hour: 8, minute: 30),
          location: 'Reno-Tahoe International Airport',
          category: ItineraryCategory.travel,
          latitude: 39.4991,
          longitude: -119.7681,
        ),
        ItineraryItem(
          title: 'Pick up rental car',
          time: const TimeOfDay(hour: 11, minute: 0),
          location: 'Airport Rental Car Center',
          category: ItineraryCategory.travel,
        ),
        ItineraryItem(
          title: 'Check in at cabin',
          time: const TimeOfDay(hour: 14, minute: 0),
          location: 'Tahoe Pines Cabin',
          category: ItineraryCategory.lodging,
          latitude: 39.0968,
          longitude: -120.0324,
        ),
        ItineraryItem(
          title: 'Family dinner by the lake',
          time: const TimeOfDay(hour: 18, minute: 30),
          location: 'Sunset Grill',
          category: ItineraryCategory.food,
        ),
      ],
    ),
    ItineraryDay(
      date: DateTime.now().add(const Duration(days: 22)),
      title: 'Lake Day',
      items: [
        ItineraryItem(
          title: 'Kayaking on the lake',
          time: const TimeOfDay(hour: 9, minute: 0),
          location: 'Sand Harbor Beach',
          category: ItineraryCategory.activity,
          latitude: 39.1985,
          longitude: -119.9294,
        ),
        ItineraryItem(
          title: 'Picnic lunch',
          time: const TimeOfDay(hour: 12, minute: 30),
          location: 'Sand Harbor Beach',
          category: ItineraryCategory.food,
        ),
        ItineraryItem(
          title: 'Hike to Eagle Falls',
          time: const TimeOfDay(hour: 15, minute: 0),
          location: 'Eagle Falls Trailhead',
          category: ItineraryCategory.activity,
          latitude: 38.9987,
          longitude: -120.1188,
        ),
      ],
    ),
    ItineraryDay(
      date: DateTime.now().add(const Duration(days: 23)),
      title: 'Explore Town',
      items: [
        ItineraryItem(
          title: 'Farmers market',
          time: const TimeOfDay(hour: 10, minute: 0),
          location: 'Downtown South Lake Tahoe',
          category: ItineraryCategory.activity,
        ),
        ItineraryItem(
          title: 'Mini golf',
          time: const TimeOfDay(hour: 14, minute: 0),
          location: 'Magic Carpet Golf',
          category: ItineraryCategory.activity,
        ),
      ],
    ),
  ];

  List<ItineraryDay> get days => List.unmodifiable(_days);
}

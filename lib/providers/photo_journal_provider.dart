import 'package:flutter/material.dart';
import '../models/photo_entry.dart';

class PhotoJournalProvider extends ChangeNotifier {
  final List<PhotoEntry> _photos = [
    PhotoEntry(
      id: 'ph1',
      tripId: 'trip-tahoe',
      caption: 'Planning the route!',
      takenBy: 'Mom',
      date: DateTime.now().subtract(const Duration(days: 5)),
      emoji: '🗺️',
    ),
    PhotoEntry(
      id: 'ph2',
      tripId: 'trip-tahoe',
      caption: 'New hiking boots arrived',
      takenBy: 'Dad',
      date: DateTime.now().subtract(const Duration(days: 3)),
      emoji: '🥾',
    ),
    PhotoEntry(
      id: 'ph3',
      tripId: 'trip-tahoe',
      caption: 'Family hike through the pines',
      takenBy: 'Mom',
      date: DateTime.now().subtract(const Duration(days: 1)),
      emoji: '🌲',
      isFavorite: true,
    ),
    PhotoEntry(
      id: 'ph4',
      tripId: 'trip-tahoe',
      caption: 'Snack break on the trail',
      takenBy: 'Dad',
      date: DateTime.now(),
      emoji: '🍎',
    ),
    PhotoEntry(
      id: 'ph5',
      tripId: 'trip-japan',
      caption: 'Learning basic Japanese phrases',
      takenBy: 'Kids',
      date: DateTime.now().subtract(const Duration(days: 20)),
      emoji: '📖',
    ),
    PhotoEntry(
      id: 'ph6',
      tripId: 'trip-japan',
      caption: 'Booked the ryokan!',
      takenBy: 'Mom',
      date: DateTime.now().subtract(const Duration(days: 45)),
      emoji: '🏯',
    ),
    PhotoEntry(
      id: 'ph7',
      tripId: 'trip-italy',
      caption: 'Colosseum at sunset',
      takenBy: 'Dad',
      date: DateTime.now().subtract(const Duration(days: 200)),
      emoji: '🏛️',
      isFavorite: true,
    ),
    PhotoEntry(
      id: 'ph8',
      tripId: 'trip-italy',
      caption: 'Best gelato in Florence',
      takenBy: 'Kids',
      date: DateTime.now().subtract(const Duration(days: 197)),
      emoji: '🍦',
    ),
    PhotoEntry(
      id: 'ph9',
      tripId: 'trip-italy',
      caption: 'Venice canals by gondola',
      takenBy: 'Mom',
      date: DateTime.now().subtract(const Duration(days: 193)),
      emoji: '🚤',
    ),
  ];

  List<PhotoEntry> get photos => List.unmodifiable(_photos);

  List<PhotoEntry> forTrip(String tripId) =>
      _photos.where((p) => p.tripId == tripId).toList();

  void addPhoto(PhotoEntry photo) {
    _photos.add(photo);
    notifyListeners();
  }
}

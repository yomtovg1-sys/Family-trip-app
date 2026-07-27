import 'package:flutter/material.dart';
import '../models/photo_entry.dart';

class PhotoJournalProvider extends ChangeNotifier {
  final List<PhotoEntry> _photos = [
    PhotoEntry(
      id: 'ph1',
      caption: 'Planning the route!',
      takenBy: 'Mom',
      date: DateTime.now().subtract(const Duration(days: 3)),
      emoji: '🗺️',
    ),
    PhotoEntry(
      id: 'ph2',
      caption: 'New hiking boots arrived',
      takenBy: 'Dad',
      date: DateTime.now().subtract(const Duration(days: 1)),
      emoji: '🥾',
    ),
  ];

  List<PhotoEntry> get photos => List.unmodifiable(_photos);

  void addPhoto(PhotoEntry photo) {
    _photos.add(photo);
    notifyListeners();
  }
}

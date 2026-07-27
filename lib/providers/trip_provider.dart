import 'package:flutter/material.dart';
import '../models/trip.dart';

class TripProvider extends ChangeNotifier {
  Trip _trip = Trip(
    name: 'Griswold Family Summer Adventure',
    destination: 'Lake Tahoe, California',
    startDate: DateTime.now().add(const Duration(days: 21)),
    endDate: DateTime.now().add(const Duration(days: 28)),
    heroEmoji: '🏔️',
  );

  Trip get trip => _trip;

  void updateTrip(Trip trip) {
    _trip = trip;
    notifyListeners();
  }
}

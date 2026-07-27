import 'package:flutter/material.dart';
import '../models/reservation.dart';

class ReservationsProvider extends ChangeNotifier {
  final List<Reservation> _reservations = [
    Reservation(
      id: 'r1',
      tripId: 'trip-tahoe',
      type: ReservationType.flight,
      title: 'Delta Airlines DL 1204',
      confirmationNumber: 'ABZ4KP',
      start: DateTime.now().add(const Duration(days: 21, hours: 8, minutes: 30)),
      end: DateTime.now().add(const Duration(days: 21, hours: 10, minutes: 45)),
      details: 'SFO → RNO, 2 adults, 2 children',
    ),
    Reservation(
      id: 'r2',
      tripId: 'trip-tahoe',
      type: ReservationType.car,
      title: 'Enterprise SUV Rental',
      confirmationNumber: 'ENT-778820',
      start: DateTime.now().add(const Duration(days: 21, hours: 11)),
      end: DateTime.now().add(const Duration(days: 28, hours: 9)),
      details: 'Pickup & drop-off at Reno-Tahoe Airport',
    ),
    Reservation(
      id: 'r3',
      tripId: 'trip-tahoe',
      type: ReservationType.hotel,
      title: 'Tahoe Pines Cabin',
      confirmationNumber: 'VRB-559012',
      start: DateTime.now().add(const Duration(days: 21, hours: 14)),
      end: DateTime.now().add(const Duration(days: 28, hours: 11)),
      details: '3 bed / 2 bath, lake view, check-in code sent by host',
    ),
    Reservation(
      id: 'r4',
      tripId: 'trip-japan',
      type: ReservationType.flight,
      title: 'ANA Flight NH 106',
      confirmationNumber: 'JPN7QX',
      start: DateTime.now().add(const Duration(days: 410, hours: 10)),
      end: DateTime.now().add(const Duration(days: 411, hours: 14)),
      details: 'SFO → HND, 2 adults, 2 children',
    ),
    Reservation(
      id: 'r5',
      tripId: 'trip-japan',
      type: ReservationType.hotel,
      title: 'Shinjuku Family Suites',
      confirmationNumber: 'RYK-33210',
      start: DateTime.now().add(const Duration(days: 411, hours: 15)),
      end: DateTime.now().add(const Duration(days: 414)),
      details: 'Family suite, 2 nights, near Shinjuku Station',
    ),
    Reservation(
      id: 'r6',
      tripId: 'trip-italy',
      type: ReservationType.flight,
      title: 'Alitalia AZ 608',
      confirmationNumber: 'ITL9PL',
      start: DateTime.now().subtract(const Duration(days: 201)).add(const Duration(hours: 9)),
      end: DateTime.now().subtract(const Duration(days: 200)).add(const Duration(hours: 12)),
      details: 'SFO → FCO, 2 adults, 2 children',
    ),
    Reservation(
      id: 'r7',
      tripId: 'trip-italy',
      type: ReservationType.hotel,
      title: 'Hotel Artemide Rome',
      confirmationNumber: 'HTL-22841',
      start: DateTime.now().subtract(const Duration(days: 201)),
      end: DateTime.now().subtract(const Duration(days: 198)),
      details: '2 connecting rooms, breakfast included',
    ),
  ];

  List<Reservation> get reservations => List.unmodifiable(_reservations);

  List<Reservation> forTrip(String tripId) =>
      _reservations.where((r) => r.tripId == tripId).toList();

  List<Reservation> byType(ReservationType type) =>
      _reservations.where((r) => r.type == type).toList();

  void addReservation(Reservation reservation) {
    _reservations.add(reservation);
    notifyListeners();
  }
}

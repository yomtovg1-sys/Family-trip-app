import 'package:flutter/material.dart';
import '../models/reservation.dart';

class ReservationsProvider extends ChangeNotifier {
  final List<Reservation> _reservations = [
    Reservation(
      id: 'r1',
      type: ReservationType.flight,
      title: 'Delta Airlines DL 1204',
      confirmationNumber: 'ABZ4KP',
      start: DateTime.now().add(const Duration(days: 21, hours: 8, minutes: 30)),
      end: DateTime.now().add(const Duration(days: 21, hours: 10, minutes: 45)),
      details: 'SFO → RNO, 2 adults, 2 children',
    ),
    Reservation(
      id: 'r2',
      type: ReservationType.car,
      title: 'Enterprise SUV Rental',
      confirmationNumber: 'ENT-778820',
      start: DateTime.now().add(const Duration(days: 21, hours: 11)),
      end: DateTime.now().add(const Duration(days: 28, hours: 9)),
      details: 'Pickup & drop-off at Reno-Tahoe Airport',
    ),
    Reservation(
      id: 'r3',
      type: ReservationType.hotel,
      title: 'Tahoe Pines Cabin',
      confirmationNumber: 'VRB-559012',
      start: DateTime.now().add(const Duration(days: 21, hours: 14)),
      end: DateTime.now().add(const Duration(days: 28, hours: 11)),
      details: '3 bed / 2 bath, lake view, check-in code sent by host',
    ),
  ];

  List<Reservation> get reservations => List.unmodifiable(_reservations);

  List<Reservation> byType(ReservationType type) =>
      _reservations.where((r) => r.type == type).toList();

  void addReservation(Reservation reservation) {
    _reservations.add(reservation);
    notifyListeners();
  }
}

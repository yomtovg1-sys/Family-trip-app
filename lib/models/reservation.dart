import 'package:flutter/material.dart';

enum ReservationType { flight, hotel, car }

extension ReservationTypeX on ReservationType {
  IconData get icon {
    switch (this) {
      case ReservationType.flight:
        return Icons.flight_takeoff;
      case ReservationType.hotel:
        return Icons.hotel;
      case ReservationType.car:
        return Icons.directions_car;
    }
  }

  String get label {
    switch (this) {
      case ReservationType.flight:
        return 'Flight';
      case ReservationType.hotel:
        return 'Hotel';
      case ReservationType.car:
        return 'Rental Car';
    }
  }
}

class Reservation {
  final String id;
  final ReservationType type;
  final String title;
  final String confirmationNumber;
  final DateTime start;
  final DateTime? end;
  final String details;

  const Reservation({
    required this.id,
    required this.type,
    required this.title,
    required this.confirmationNumber,
    required this.start,
    this.end,
    required this.details,
  });
}

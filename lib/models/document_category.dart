import 'package:flutter/material.dart';

/// What kind of document this is — the single category system used
/// everywhere a document shows up: Personal Vault items, trip-level Travel
/// Wallet documents, and reservation attachments alike. Previously three
/// separate, overlapping enums (a general document tag, a trip-document
/// category, and a vault-document category) each modeled this same idea
/// slightly differently; this is the one place it's defined now, so "this
/// is a passport" means the same thing everywhere in the app.
enum DocumentCategory {
  passport,
  driverLicense,
  internationalDrivingPermit,
  insurance,
  visa,
  vaccination,
  emergencyContact,
  frequentFlyer,
  loungeMembership,
  flight,
  hotel,
  carRental,
  tickets,
  other,
}

extension DocumentCategoryX on DocumentCategory {
  String get label {
    switch (this) {
      case DocumentCategory.passport:
        return 'Passport';
      case DocumentCategory.driverLicense:
        return 'Driver License';
      case DocumentCategory.internationalDrivingPermit:
        return 'International Driving Permit';
      case DocumentCategory.insurance:
        return 'Insurance';
      case DocumentCategory.visa:
        return 'Visa';
      case DocumentCategory.vaccination:
        return 'Vaccination';
      case DocumentCategory.emergencyContact:
        return 'Emergency Contact';
      case DocumentCategory.frequentFlyer:
        return 'Frequent Flyer Card';
      case DocumentCategory.loungeMembership:
        return 'Lounge Membership';
      case DocumentCategory.flight:
        return 'Flight';
      case DocumentCategory.hotel:
        return 'Hotel';
      case DocumentCategory.carRental:
        return 'Car Rental';
      case DocumentCategory.tickets:
        return 'Tickets';
      case DocumentCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentCategory.passport:
        return Icons.badge_rounded;
      case DocumentCategory.driverLicense:
        return Icons.directions_car_filled_rounded;
      case DocumentCategory.internationalDrivingPermit:
        return Icons.card_travel_rounded;
      case DocumentCategory.insurance:
        return Icons.health_and_safety_rounded;
      case DocumentCategory.visa:
        return Icons.travel_explore_rounded;
      case DocumentCategory.vaccination:
        return Icons.vaccines_rounded;
      case DocumentCategory.emergencyContact:
        return Icons.emergency_rounded;
      case DocumentCategory.frequentFlyer:
        return Icons.flight_rounded;
      case DocumentCategory.loungeMembership:
        return Icons.airline_seat_flat_rounded;
      case DocumentCategory.flight:
        return Icons.flight_rounded;
      case DocumentCategory.hotel:
        return Icons.hotel_rounded;
      case DocumentCategory.carRental:
        return Icons.directions_car_rounded;
      case DocumentCategory.tickets:
        return Icons.confirmation_number_rounded;
      case DocumentCategory.other:
        return Icons.folder_rounded;
    }
  }

  Color get color {
    switch (this) {
      case DocumentCategory.passport:
        return const Color(0xFF3A6EA5);
      case DocumentCategory.driverLicense:
        return const Color(0xFFE8590C);
      case DocumentCategory.internationalDrivingPermit:
        return const Color(0xFFB5651D);
      case DocumentCategory.insurance:
        return const Color(0xFF2F9E44);
      case DocumentCategory.visa:
        return const Color(0xFF2B8A8A);
      case DocumentCategory.vaccination:
        return const Color(0xFF7986CB);
      case DocumentCategory.emergencyContact:
        return const Color(0xFFE53935);
      case DocumentCategory.frequentFlyer:
        return const Color(0xFF6741D9);
      case DocumentCategory.loungeMembership:
        return const Color(0xFF00838F);
      case DocumentCategory.flight:
        return const Color(0xFF3A6EA5);
      case DocumentCategory.hotel:
        return const Color(0xFF7986CB);
      case DocumentCategory.carRental:
        return const Color(0xFF2F9E44);
      case DocumentCategory.tickets:
        return const Color(0xFFD6336C);
      case DocumentCategory.other:
        return const Color(0xFF757575);
    }
  }
}

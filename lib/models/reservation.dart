import 'package:flutter/material.dart';
import 'document_category.dart';
import 'travel_document.dart';

enum ReservationCategory { flight, hotel, transportation, ticket, other }

extension ReservationCategoryX on ReservationCategory {
  String get emoji {
    switch (this) {
      case ReservationCategory.flight:
        return '✈️';
      case ReservationCategory.hotel:
        return '🏨';
      case ReservationCategory.transportation:
        return '🚗';
      case ReservationCategory.ticket:
        return '🎟️';
      case ReservationCategory.other:
        return '📌';
    }
  }

  IconData get icon {
    switch (this) {
      case ReservationCategory.flight:
        return Icons.flight_rounded;
      case ReservationCategory.hotel:
        return Icons.hotel_rounded;
      case ReservationCategory.transportation:
        return Icons.directions_car_rounded;
      case ReservationCategory.ticket:
        return Icons.confirmation_number_rounded;
      case ReservationCategory.other:
        return Icons.bookmark_rounded;
    }
  }

  String get label {
    switch (this) {
      case ReservationCategory.flight:
        return 'Flights';
      case ReservationCategory.hotel:
        return 'Hotels';
      case ReservationCategory.transportation:
        return 'Transportation';
      case ReservationCategory.ticket:
        return 'Tickets';
      case ReservationCategory.other:
        return 'Other';
    }
  }

  String get singularLabel {
    switch (this) {
      case ReservationCategory.flight:
        return 'Flight';
      case ReservationCategory.hotel:
        return 'Hotel';
      case ReservationCategory.transportation:
        return 'Transportation';
      case ReservationCategory.ticket:
        return 'Ticket';
      case ReservationCategory.other:
        return 'Other';
    }
  }

  Color get color {
    switch (this) {
      case ReservationCategory.flight:
        return const Color(0xFF3A6EA5);
      case ReservationCategory.hotel:
        return const Color(0xFF7986CB);
      case ReservationCategory.transportation:
        return const Color(0xFF2F9E44);
      case ReservationCategory.ticket:
        return const Color(0xFFE8590C);
      case ReservationCategory.other:
        return const Color(0xFF6C63FF);
    }
  }

  /// The sensible default [DocumentCategory] for a document uploaded to a
  /// reservation of this category, so every upload gets a useful category
  /// without an extra picker step.
  DocumentCategory get defaultDocumentCategory {
    switch (this) {
      case ReservationCategory.flight:
        return DocumentCategory.flight;
      case ReservationCategory.hotel:
        return DocumentCategory.hotel;
      case ReservationCategory.transportation:
        return DocumentCategory.carRental;
      case ReservationCategory.ticket:
        return DocumentCategory.tickets;
      case ReservationCategory.other:
        return DocumentCategory.other;
    }
  }
}

enum ReservationStatus { upcoming, completed, cancelled }

extension ReservationStatusX on ReservationStatus {
  String get label {
    switch (this) {
      case ReservationStatus.upcoming:
        return 'Upcoming';
      case ReservationStatus.completed:
        return 'Completed';
      case ReservationStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case ReservationStatus.upcoming:
        return const Color(0xFF2E7D6B);
      case ReservationStatus.completed:
        return const Color(0xFF757575);
      case ReservationStatus.cancelled:
        return const Color(0xFFE53935);
    }
  }
}

class Reservation {
  final String id;
  final String tripId;
  final ReservationCategory category;
  final String? subtype;
  final String title;
  final DateTime dateTime;
  final DateTime? endDateTime;
  final String location;
  final String confirmationNumber;
  final String provider;
  final String? phone;
  final String? website;
  final String? notes;
  final ReservationStatus status;
  final List<TravelDocument> attachments;

  const Reservation({
    required this.id,
    required this.tripId,
    required this.category,
    this.subtype,
    required this.title,
    required this.dateTime,
    this.endDateTime,
    required this.location,
    required this.confirmationNumber,
    required this.provider,
    this.phone,
    this.website,
    this.notes,
    this.status = ReservationStatus.upcoming,
    this.attachments = const [],
  });

  Reservation copyWith({
    ReservationCategory? category,
    String? subtype,
    String? title,
    DateTime? dateTime,
    DateTime? endDateTime,
    String? location,
    String? confirmationNumber,
    String? provider,
    String? phone,
    String? website,
    String? notes,
    ReservationStatus? status,
    List<TravelDocument>? attachments,
  }) {
    return Reservation(
      id: id,
      tripId: tripId,
      category: category ?? this.category,
      subtype: subtype ?? this.subtype,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      location: location ?? this.location,
      confirmationNumber: confirmationNumber ?? this.confirmationNumber,
      provider: provider ?? this.provider,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
    );
  }

  bool get isUpcoming => status == ReservationStatus.upcoming;

  Map<String, dynamic> toJson() => {
        'id': id,
        'tripId': tripId,
        'category': category.name,
        'subtype': subtype,
        'title': title,
        'dateTime': dateTime.toIso8601String(),
        'endDateTime': endDateTime?.toIso8601String(),
        'location': location,
        'confirmationNumber': confirmationNumber,
        'provider': provider,
        'phone': phone,
        'website': website,
        'notes': notes,
        'status': status.name,
        'attachments': [for (final a in attachments) a.toJson()],
      };

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      category: ReservationCategory.values.byName(json['category'] as String),
      subtype: json['subtype'] as String?,
      title: json['title'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      endDateTime:
          json['endDateTime'] != null ? DateTime.parse(json['endDateTime'] as String) : null,
      location: json['location'] as String,
      confirmationNumber: json['confirmationNumber'] as String,
      provider: json['provider'] as String,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] != null
          ? ReservationStatus.values.byName(json['status'] as String)
          : ReservationStatus.upcoming,
      attachments: [
        for (final a in (json['attachments'] as List? ?? const []))
          TravelDocument.fromJson(a as Map<String, dynamic>),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../models/document_category.dart';
import '../models/reservation.dart';
import '../models/travel_document.dart';
import '../services/hive_json_store.dart';
import '../utils/placeholder_bytes.dart';

class ReservationsProvider extends ChangeNotifier {
  final HiveJsonStore<Reservation> _store;
  final List<Reservation> _reservations;

  ReservationsProvider._(this._store, this._reservations);

  static Future<ReservationsProvider> open() async {
    final store = await HiveJsonStore.open<Reservation>(
      'reservations',
      toJson: (r) => r.toJson(),
      fromJson: Reservation.fromJson,
      idOf: (r) => r.id,
    );
    final reservations = store.isEmpty ? _seedReservations() : store.getAll();
    if (store.isEmpty) store.putAll(reservations);
    return ReservationsProvider._(store, reservations);
  }

  List<Reservation> get reservations => List.unmodifiable(_reservations);

  List<Reservation> forTrip(String tripId) =>
      _reservations.where((r) => r.tripId == tripId).toList();

  Reservation? nextUpcoming(String tripId) {
    final now = DateTime.now();
    final upcoming = forTrip(tripId)
        .where((r) => r.status == ReservationStatus.upcoming && r.dateTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  List<Reservation> search(
    String tripId, {
    String query = '',
    ReservationCategory? category,
    ReservationStatus? status,
  }) {
    final lowerQuery = query.trim().toLowerCase();
    return forTrip(tripId).where((r) {
      final matchesCategory = category == null || r.category == category;
      final matchesStatus = status == null || r.status == status;
      final matchesQuery = lowerQuery.isEmpty ||
          r.title.toLowerCase().contains(lowerQuery) ||
          r.provider.toLowerCase().contains(lowerQuery) ||
          r.location.toLowerCase().contains(lowerQuery) ||
          r.confirmationNumber.toLowerCase().contains(lowerQuery);
      return matchesCategory && matchesStatus && matchesQuery;
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  /// Groups reservations by calendar day for the timeline view.
  Map<DateTime, List<Reservation>> groupByDate(List<Reservation> items) {
    final map = <DateTime, List<Reservation>>{};
    for (final r in items) {
      final day = DateTime(r.dateTime.year, r.dateTime.month, r.dateTime.day);
      map.putIfAbsent(day, () => []).add(r);
    }
    return map;
  }

  Reservation? byId(String id) {
    for (final r in _reservations) {
      if (r.id == id) return r;
    }
    return null;
  }

  void addReservation(Reservation reservation) {
    _reservations.add(reservation);
    _store.put(reservation);
    notifyListeners();
  }

  void updateReservation(Reservation updated) {
    final index = _reservations.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      _reservations[index] = updated;
      _store.put(updated);
      notifyListeners();
    }
  }

  void deleteReservation(String id) {
    _reservations.removeWhere((r) => r.id == id);
    _store.remove(id);
    notifyListeners();
  }

  /// Replaces every reservation for [tripId] with [reservations] — used to
  /// apply a backup restore or import.
  void replaceForTrip(String tripId, List<Reservation> reservations) {
    _reservations.removeWhere((r) => r.tripId == tripId);
    _reservations.addAll(reservations);
    _store.replaceAll(_reservations);
    notifyListeners();
  }

  void addAttachment(String reservationId, TravelDocument attachment) {
    final r = byId(reservationId);
    if (r != null) {
      updateReservation(r.copyWith(attachments: [...r.attachments, attachment]));
    }
  }

  void renameAttachment(String reservationId, String attachmentId, String newName) {
    final r = byId(reservationId);
    if (r == null) return;
    updateReservation(
      r.copyWith(
        attachments: [
          for (final a in r.attachments)
            if (a.id == attachmentId) a.copyWith(fileName: newName) else a,
        ],
      ),
    );
  }

  void removeAttachment(String reservationId, String attachmentId) {
    final r = byId(reservationId);
    if (r != null) {
      updateReservation(
        r.copyWith(
          attachments: r.attachments.where((a) => a.id != attachmentId).toList(),
        ),
      );
    }
  }

  static List<Reservation> _seedReservations() {
    final now = DateTime.now();

    return [
      // --- Lake Tahoe (upcoming trip) ---
      Reservation(
        id: 'r1',
        tripId: 'trip-tahoe',
        category: ReservationCategory.flight,
        title: 'Flight to Reno-Tahoe',
        dateTime: now.add(const Duration(days: 21, hours: 8, minutes: 30)),
        endDateTime: now.add(const Duration(days: 21, hours: 10, minutes: 45)),
        location: 'San Francisco Intl (SFO) → Reno-Tahoe Intl (RNO)',
        confirmationNumber: 'ABZ4KP',
        provider: 'Delta Airlines',
        phone: '+1 800-221-1212',
        website: 'https://www.delta.com',
        notes: '2 adults, 2 children. Seats 14A-14D.',
        attachments: [
          TravelDocument(
            id: 'a1',
            fileName: 'Boarding Passes.pdf',
            type: AttachmentType.pdf,
            bytes: placeholderDocumentBytes,
            uploadedAt: now.subtract(const Duration(days: 2)),
            category: DocumentCategory.flight,
          ),
        ],
      ),
      Reservation(
        id: 'r2',
        tripId: 'trip-tahoe',
        category: ReservationCategory.transportation,
        subtype: 'Rental Car',
        title: 'Rental Car Pickup',
        dateTime: now.add(const Duration(days: 21, hours: 11)),
        endDateTime: now.add(const Duration(days: 28, hours: 9)),
        location: 'Reno-Tahoe Airport Rental Car Center',
        confirmationNumber: 'ENT-778820',
        provider: 'Enterprise',
        phone: '+1 855-266-9565',
        website: 'https://www.enterprise.com',
      ),
      Reservation(
        id: 'r3',
        tripId: 'trip-tahoe',
        category: ReservationCategory.hotel,
        title: 'Hotel Check-in',
        dateTime: now.add(const Duration(days: 21, hours: 14)),
        endDateTime: now.add(const Duration(days: 28, hours: 11)),
        location: 'Tahoe Pines Cabin, South Lake Tahoe',
        confirmationNumber: 'VRB-559012',
        provider: 'Vrbo Host: The Reyes Family',
        website: 'https://www.vrbo.com',
        notes: '3 bed / 2 bath, lake view. Check-in code sent by host.',
        attachments: [
          TravelDocument(
            id: 'a2',
            fileName: 'Booking Confirmation.pdf',
            type: AttachmentType.pdf,
            bytes: placeholderDocumentBytes,
            uploadedAt: now.subtract(const Duration(days: 8)),
            category: DocumentCategory.hotel,
          ),
          TravelDocument(
            id: 'a3',
            fileName: 'Check-in QR Code.png',
            type: AttachmentType.image,
            bytes: placeholderImageBytes,
            uploadedAt: now.subtract(const Duration(days: 1)),
            category: DocumentCategory.hotel,
          ),
        ],
      ),
      Reservation(
        id: 'r4',
        tripId: 'trip-tahoe',
        category: ReservationCategory.ticket,
        subtype: 'Tour',
        title: 'Sand Harbor Kayak Tour',
        dateTime: now.add(const Duration(days: 22, hours: 9)),
        endDateTime: now.add(const Duration(days: 22, hours: 11)),
        location: 'Sand Harbor Beach, Lake Tahoe',
        confirmationNumber: 'TAH-4471',
        provider: 'Tahoe Adventure Co.',
        website: 'https://www.tahoeadventureco.com',
        notes: 'Life jackets provided for kids.',
        attachments: [
          TravelDocument(
            id: 'a4',
            fileName: 'Kayak Tour Voucher.pdf',
            type: AttachmentType.pdf,
            bytes: placeholderDocumentBytes,
            uploadedAt: now.subtract(const Duration(hours: 12)),
            category: DocumentCategory.tickets,
          ),
        ],
      ),

      // --- Japan (far-future trip) ---
      Reservation(
        id: 'r5',
        tripId: 'trip-japan',
        category: ReservationCategory.flight,
        title: 'Flight to Tokyo',
        dateTime: now.add(const Duration(days: 410, hours: 10)),
        endDateTime: now.add(const Duration(days: 411, hours: 14)),
        location: 'San Francisco Intl (SFO) → Haneda Airport (HND)',
        confirmationNumber: 'JPN7QX',
        provider: 'ANA',
        phone: '+1 800-235-9262',
        website: 'https://www.ana.co.jp',
        notes: '2 adults, 2 children.',
      ),
      Reservation(
        id: 'r6',
        tripId: 'trip-japan',
        category: ReservationCategory.hotel,
        title: 'Hotel Check-in',
        dateTime: now.add(const Duration(days: 411, hours: 15)),
        endDateTime: now.add(const Duration(days: 414)),
        location: 'Shinjuku Family Suites, Tokyo',
        confirmationNumber: 'RYK-33210',
        provider: 'Shinjuku Family Suites',
        website: 'https://www.shinjukufamilysuites.example',
        notes: 'Family suite, 2 connecting rooms.',
      ),
      Reservation(
        id: 'r7',
        tripId: 'trip-japan',
        category: ReservationCategory.transportation,
        subtype: 'Train',
        title: 'JR Rail Pass Activation',
        dateTime: now.add(const Duration(days: 411, hours: 9)),
        location: 'JR East Travel Service Center, Tokyo Station',
        confirmationNumber: 'JR-88213',
        provider: 'Japan Rail',
        website: 'https://www.jreast.co.jp',
      ),
      Reservation(
        id: 'r8',
        tripId: 'trip-japan',
        category: ReservationCategory.ticket,
        subtype: 'Museum',
        title: 'teamLab Planets Tokyo',
        dateTime: now.add(const Duration(days: 412, hours: 13)),
        location: 'Toyosu, Tokyo',
        confirmationNumber: 'TLP-99871',
        provider: 'teamLab',
        website: 'https://www.teamlab.art',
        notes: 'Wear shorts — some rooms involve wading through water.',
      ),

      // --- Italy (completed trip) ---
      Reservation(
        id: 'r9',
        tripId: 'trip-italy',
        category: ReservationCategory.flight,
        title: 'Flight to Rome',
        dateTime: now.subtract(const Duration(days: 201)).add(const Duration(hours: 9)),
        endDateTime: now.subtract(const Duration(days: 200)).add(const Duration(hours: 12)),
        location: 'San Francisco Intl (SFO) → Fiumicino (FCO)',
        confirmationNumber: 'ITL9PL',
        provider: 'Alitalia',
        website: 'https://www.ita-airways.com',
        status: ReservationStatus.completed,
      ),
      Reservation(
        id: 'r10',
        tripId: 'trip-italy',
        category: ReservationCategory.hotel,
        title: 'Hotel Check-in',
        dateTime: now.subtract(const Duration(days: 201)),
        endDateTime: now.subtract(const Duration(days: 198)),
        location: 'Hotel Artemide, Rome',
        confirmationNumber: 'HTL-22841',
        provider: 'Hotel Artemide',
        website: 'https://www.hotelartemide.it',
        notes: '2 connecting rooms, breakfast included.',
        status: ReservationStatus.completed,
      ),
      Reservation(
        id: 'r11',
        tripId: 'trip-italy',
        category: ReservationCategory.transportation,
        subtype: 'Ferry',
        title: 'Venice Water Taxi',
        dateTime: now.subtract(const Duration(days: 193)).add(const Duration(hours: 10)),
        location: 'Venice Santa Lucia to Hotel Dock',
        confirmationNumber: 'VEN-5521',
        provider: 'Venezia Water Taxi Co.',
        status: ReservationStatus.completed,
      ),
      Reservation(
        id: 'r12',
        tripId: 'trip-italy',
        category: ReservationCategory.ticket,
        subtype: 'Tour',
        title: 'Colosseum Underground Tour',
        dateTime: now.subtract(const Duration(days: 200)).add(const Duration(hours: 10)),
        location: 'Colosseum, Rome',
        confirmationNumber: 'COL-77102',
        provider: 'Rome Guided Tours',
        website: 'https://www.romeguidedtours.example',
        status: ReservationStatus.completed,
      ),
      Reservation(
        id: 'r13',
        tripId: 'trip-italy',
        category: ReservationCategory.ticket,
        subtype: 'Museum',
        title: 'Vatican Museums Skip-the-Line',
        dateTime: now.subtract(const Duration(days: 199)).add(const Duration(hours: 14)),
        location: 'Vatican Museums, Vatican City',
        confirmationNumber: 'VAT-31029',
        provider: 'Vatican Museums',
        status: ReservationStatus.cancelled,
        notes: 'Cancelled — replaced with a private tour instead.',
      ),
    ];
  }
}

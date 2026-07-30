import 'package:flutter/material.dart';
import '../models/reservation.dart';
import '../models/travel_document.dart';
import '../services/hive_json_store.dart';

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
    return ReservationsProvider._(store, store.getAll());
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
}

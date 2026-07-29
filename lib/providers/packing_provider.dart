import 'package:flutter/material.dart';
import '../models/packing_item.dart';

/// Packing checklists, scoped per trip — each trip keeps its own list, so
/// switching trips shows a different checklist rather than one shared list.
class PackingProvider extends ChangeNotifier {
  final List<PackingItem> _items = [
    PackingItem(id: 'p1', tripId: 'trip-tahoe', name: 'Swimsuits', category: 'Clothing', assignedTo: 'Everyone'),
    PackingItem(id: 'p2', tripId: 'trip-tahoe', name: 'Hiking boots', category: 'Clothing', assignedTo: 'Dad'),
    PackingItem(id: 'p3', tripId: 'trip-tahoe', name: 'Sunscreen', category: 'Toiletries', assignedTo: 'Mom'),
    PackingItem(
      id: 'p4',
      tripId: 'trip-tahoe',
      name: 'Kids tablets & chargers',
      category: 'Electronics',
      assignedTo: 'Kids',
    ),
    PackingItem(id: 'p5', tripId: 'trip-tahoe', name: 'Camping chairs', category: 'Gear', assignedTo: 'Dad'),
    PackingItem(id: 'p6', tripId: 'trip-tahoe', name: 'First aid kit', category: 'Essentials', assignedTo: 'Mom'),
    PackingItem(
      id: 'p7',
      tripId: 'trip-tahoe',
      name: 'Passports / IDs',
      category: 'Essentials',
      assignedTo: 'Everyone',
    ),
    PackingItem(id: 'p8', tripId: 'trip-tahoe', name: 'Snacks for the road', category: 'Food', assignedTo: 'Kids'),
  ];

  /// Every packing item across every trip — used for whole-app backup/AI
  /// grounding fallbacks, not for display (use [forTrip] for that).
  List<PackingItem> get items => List.unmodifiable(_items);

  List<PackingItem> forTrip(String tripId) => _items.where((i) => i.tripId == tripId).toList();

  void togglePacked(String id) {
    final item = _items.firstWhere((i) => i.id == id);
    item.isPacked = !item.isPacked;
    notifyListeners();
  }

  void addItem(PackingItem item) {
    _items.add(item);
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  /// Replaces every packing item for [tripId] with [items] — used to apply a
  /// backup restore/import or a trip-to-trip copy.
  void replaceForTrip(String tripId, List<PackingItem> items) {
    _items.removeWhere((i) => i.tripId == tripId);
    _items.addAll(items);
    notifyListeners();
  }

  /// Replaces the entire packing list across every trip — used for a
  /// whole-app backup restore.
  void replaceAll(List<PackingItem> items) {
    _items
      ..clear()
      ..addAll(items);
    notifyListeners();
  }
}

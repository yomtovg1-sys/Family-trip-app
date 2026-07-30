import 'package:flutter/material.dart';
import '../models/packing_item.dart';
import '../services/hive_json_store.dart';

/// Packing checklists, scoped per trip — each trip keeps its own list, so
/// switching trips shows a different checklist rather than one shared list.
class PackingProvider extends ChangeNotifier {
  final HiveJsonStore<PackingItem> _store;
  final List<PackingItem> _items;

  PackingProvider._(this._store, this._items);

  static Future<PackingProvider> open() async {
    final store = await HiveJsonStore.open<PackingItem>(
      'packing',
      toJson: (i) => i.toJson(),
      fromJson: PackingItem.fromJson,
      idOf: (i) => i.id,
    );
    return PackingProvider._(store, store.getAll());
  }

  /// Every packing item across every trip — used for whole-app backup/AI
  /// grounding fallbacks, not for display (use [forTrip] for that).
  List<PackingItem> get items => List.unmodifiable(_items);

  List<PackingItem> forTrip(String tripId) => _items.where((i) => i.tripId == tripId).toList();

  void togglePacked(String id) {
    final item = _items.firstWhere((i) => i.id == id);
    item.isPacked = !item.isPacked;
    _store.put(item);
    notifyListeners();
  }

  void addItem(PackingItem item) {
    _items.add(item);
    _store.put(item);
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    _store.remove(id);
    notifyListeners();
  }

  /// Replaces every packing item for [tripId] with [items] — used to apply a
  /// backup restore/import or a trip-to-trip copy.
  void replaceForTrip(String tripId, List<PackingItem> items) {
    _items.removeWhere((i) => i.tripId == tripId);
    _items.addAll(items);
    _store.replaceAll(_items);
    notifyListeners();
  }

  /// Replaces the entire packing list across every trip — used for a
  /// whole-app backup restore.
  void replaceAll(List<PackingItem> items) {
    _items
      ..clear()
      ..addAll(items);
    _store.replaceAll(_items);
    notifyListeners();
  }
}

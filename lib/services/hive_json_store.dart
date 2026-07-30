import 'dart:convert';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// A generic on-device store for a list of JSON-serializable models, backed
/// by one Hive box per model type. Every model already has `toJson`/
/// `fromJson` (built during the Sync & Backup work), so this reuses that
/// instead of introducing per-model persistence code — one store
/// implementation covers Reservations, Places, Packing, Memories, Tasks,
/// and anything else shaped like "a list of things keyed by id".
///
/// On web, Hive boxes are backed by IndexedDB, which has none of
/// `shared_preferences`/localStorage's ~5-10MB quota ceiling — the reason
/// this was chosen over extending the existing `shared_preferences`-based
/// repositories to cover these providers too.
class HiveJsonStore<T> {
  final Box<String> _box;
  final Map<String, dynamic> Function(T) _toJson;
  final T Function(Map<String, dynamic>) _fromJson;
  final String Function(T) _idOf;

  HiveJsonStore._(this._box, this._toJson, this._fromJson, this._idOf);

  static Future<HiveJsonStore<T>> open<T>(
    String boxName, {
    required Map<String, dynamic> Function(T) toJson,
    required T Function(Map<String, dynamic>) fromJson,
    required String Function(T) idOf,
  }) async {
    final box = await Hive.openBox<String>(boxName);
    return HiveJsonStore<T>._(box, toJson, fromJson, idOf);
  }

  bool get isEmpty => _box.isEmpty;

  List<T> getAll() => [for (final raw in _box.values) _fromJson(jsonDecode(raw) as Map<String, dynamic>)];

  void put(T item) => _box.put(_idOf(item), jsonEncode(_toJson(item)));

  void putAll(Iterable<T> items) {
    _box.putAll({for (final item in items) _idOf(item): jsonEncode(_toJson(item))});
  }

  void remove(String id) => _box.delete(id);

  /// Replaces the box's entire contents with [items] — the simplest way to
  /// keep storage in sync after operations that reorder, bulk-replace, or
  /// otherwise don't map cleanly onto individual put/remove calls.
  void replaceAll(List<T> items) {
    _box.clear();
    putAll(items);
  }
}

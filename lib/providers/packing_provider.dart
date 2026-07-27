import 'package:flutter/material.dart';
import '../models/packing_item.dart';

class PackingProvider extends ChangeNotifier {
  final List<PackingItem> _items = [
    PackingItem(id: 'p1', name: 'Swimsuits', category: 'Clothing', assignedTo: 'Everyone'),
    PackingItem(id: 'p2', name: 'Hiking boots', category: 'Clothing', assignedTo: 'Dad'),
    PackingItem(id: 'p3', name: 'Sunscreen', category: 'Toiletries', assignedTo: 'Mom'),
    PackingItem(id: 'p4', name: 'Kids tablets & chargers', category: 'Electronics', assignedTo: 'Kids'),
    PackingItem(id: 'p5', name: 'Camping chairs', category: 'Gear', assignedTo: 'Dad'),
    PackingItem(id: 'p6', name: 'First aid kit', category: 'Essentials', assignedTo: 'Mom'),
    PackingItem(id: 'p7', name: 'Passports / IDs', category: 'Essentials', assignedTo: 'Everyone'),
    PackingItem(id: 'p8', name: 'Snacks for the road', category: 'Food', assignedTo: 'Kids'),
  ];

  List<PackingItem> get items => List.unmodifiable(_items);

  int get packedCount => _items.where((i) => i.isPacked).length;

  double get progress => _items.isEmpty ? 0 : packedCount / _items.length;

  void togglePacked(String id) {
    final item = _items.firstWhere((i) => i.id == id);
    item.isPacked = !item.isPacked;
    notifyListeners();
  }

  void addItem(PackingItem item) {
    _items.add(item);
    notifyListeners();
  }
}

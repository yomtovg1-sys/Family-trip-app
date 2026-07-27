class PackingItem {
  final String id;
  final String name;
  final String category;
  final String assignedTo;
  bool isPacked;

  PackingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.assignedTo,
    this.isPacked = false,
  });
}

class PackingItem {
  final String id;
  final String tripId;
  final String name;
  final String category;
  final String assignedTo;
  bool isPacked;

  PackingItem({
    required this.id,
    required this.tripId,
    required this.name,
    required this.category,
    required this.assignedTo,
    this.isPacked = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'tripId': tripId,
        'name': name,
        'category': category,
        'assignedTo': assignedTo,
        'isPacked': isPacked,
      };

  factory PackingItem.fromJson(Map<String, dynamic> json) {
    return PackingItem(
      id: json['id'] as String,
      tripId: json['tripId'] as String? ?? '',
      name: json['name'] as String,
      category: json['category'] as String,
      assignedTo: json['assignedTo'] as String,
      isPacked: json['isPacked'] as bool? ?? false,
    );
  }
}

class FamilyTask {
  final String id;
  final String title;
  final String assignedTo;
  final DateTime? dueDate;
  bool isDone;

  FamilyTask({
    required this.id,
    required this.title,
    required this.assignedTo,
    this.dueDate,
    this.isDone = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'assignedTo': assignedTo,
        'dueDate': dueDate?.toIso8601String(),
        'isDone': isDone,
      };

  factory FamilyTask.fromJson(Map<String, dynamic> json) {
    return FamilyTask(
      id: json['id'] as String,
      title: json['title'] as String,
      assignedTo: json['assignedTo'] as String,
      dueDate: json['dueDate'] == null ? null : DateTime.parse(json['dueDate'] as String),
      isDone: json['isDone'] as bool? ?? false,
    );
  }
}

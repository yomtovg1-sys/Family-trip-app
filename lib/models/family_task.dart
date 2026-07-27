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
}

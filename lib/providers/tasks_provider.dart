import 'package:flutter/material.dart';
import '../models/family_task.dart';
import '../services/hive_json_store.dart';

class TasksProvider extends ChangeNotifier {
  final HiveJsonStore<FamilyTask> _store;
  final List<FamilyTask> _tasks;

  TasksProvider._(this._store, this._tasks);

  static Future<TasksProvider> open() async {
    final store = await HiveJsonStore.open<FamilyTask>(
      'tasks',
      toJson: (t) => t.toJson(),
      fromJson: FamilyTask.fromJson,
      idOf: (t) => t.id,
    );
    final tasks = store.isEmpty ? _seedTasks() : store.getAll();
    if (store.isEmpty) store.putAll(tasks);
    return TasksProvider._(store, tasks);
  }

  static List<FamilyTask> _seedTasks() => [
        FamilyTask(
          id: 't1',
          title: 'Book kayak rental',
          assignedTo: 'Mom',
          dueDate: DateTime.now().add(const Duration(days: 5)),
        ),
        FamilyTask(
          id: 't2',
          title: 'Renew car insurance travel add-on',
          assignedTo: 'Dad',
          dueDate: DateTime.now().add(const Duration(days: 7)),
        ),
        FamilyTask(
          id: 't3',
          title: 'Pack the board games',
          assignedTo: 'Kids',
          dueDate: DateTime.now().add(const Duration(days: 20)),
        ),
        FamilyTask(
          id: 't4',
          title: 'Ask neighbor to water plants',
          assignedTo: 'Mom',
          dueDate: DateTime.now().add(const Duration(days: 19)),
        ),
      ];

  List<FamilyTask> get tasks => List.unmodifiable(_tasks);

  int get openCount => _tasks.where((t) => !t.isDone).length;

  void toggleDone(String id) {
    final task = _tasks.firstWhere((t) => t.id == id);
    task.isDone = !task.isDone;
    _store.put(task);
    notifyListeners();
  }

  void addTask(FamilyTask task) {
    _tasks.add(task);
    _store.put(task);
    notifyListeners();
  }
}

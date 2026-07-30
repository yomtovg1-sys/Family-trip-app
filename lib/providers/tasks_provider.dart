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
    return TasksProvider._(store, store.getAll());
  }

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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/tasks_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_section.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tasksProvider = context.watch<TasksProvider>();
    final tasks = tasksProvider.tasks;
    final dateFormat = DateFormat('MMM d');

    return Scaffold(
      appBar: AppBar(title: const Text('Family Tasks')),
      drawer: const AppDrawer(currentRoute: AppSection.tasksRoute),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${tasksProvider.openCount} tasks left to do'),
            ),
          ),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('✅', style: TextStyle(fontSize: 44)),
                          const SizedBox(height: 16),
                          Text('Nothing to do yet', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Text(
                            'Family prep tasks will show up here.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return CheckboxListTile(
                        value: task.isDone,
                        onChanged: (_) => tasksProvider.toggleDone(task.id),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Text(
                          'Assigned to ${task.assignedTo}'
                          '${task.dueDate != null ? ' · due ${dateFormat.format(task.dueDate!)}' : ''}',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/tasks_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_section.dart';
import '../widgets/empty_state.dart';

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
                ? const EmptyState(
                    visual: Text('✅', style: TextStyle(fontSize: 44)),
                    title: 'Nothing to do yet',
                    subtitle: 'Family prep tasks will show up here.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                        child: CheckboxListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

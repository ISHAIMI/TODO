// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TodoScreen extends StatelessWidget {
  final TextEditingController _taskController = TextEditingController();

  TodoScreen({super.key});

  // Add main task
  void _addTask(BuildContext context) async {
    String taskTitle = _taskController.text;
    if (taskTitle.isNotEmpty) {
      await FirebaseFirestore.instance.collection('tasks').add({
        'title': taskTitle,
        'is_completed': false,
        'created_at': Timestamp.now(),
      });
      _taskController.clear();
      Navigator.pop(context);
    }
  }

  // Add subtask

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "TODO",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              "By ISHA",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Add Task'),
              content: TextField(
                controller: _taskController,
                decoration: const InputDecoration(hintText: 'Task title'),
              ),
              actions: [
                TextButton(
                  onPressed: () => _addTask(context),
                  child: const Text('Add'),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          var tasks = snapshot.data!.docs;
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              var task = tasks[index];
              return TaskItem(
                taskId: task.id,
                title: task['title'],
                isCompleted: task['is_completed'],
              );
            },
          );
        },
      ),
    );
  }
}

class TaskItem extends StatelessWidget {
  final String taskId;
  final String title;
  final bool isCompleted;
  final TextEditingController _subtaskController = TextEditingController();

  TaskItem(
      {super.key,
      required this.taskId,
      required this.title,
      required this.isCompleted});

  // Toggle main task completion and update all subtasks
  void _toggleCompleteAllSubtasks() async {
    final taskRef = FirebaseFirestore.instance.collection('tasks').doc(taskId);

    await taskRef.update({'is_completed': !isCompleted});

    // Fetch and update all subtasks
    final subtasksSnapshot = await taskRef.collection('subtasks').get();
    for (var subtask in subtasksSnapshot.docs) {
      subtask.reference.update({'is_completed': !isCompleted});
    }
  }

  // Delete main task and all its subtasks
  void _deleteTaskAndSubtasks() async {
    final taskRef = FirebaseFirestore.instance.collection('tasks').doc(taskId);

    // Delete subtasks first
    final subtasksSnapshot = await taskRef.collection('subtasks').get();
    for (var subtask in subtasksSnapshot.docs) {
      await subtask.reference.delete();
    }

    // Then delete the main task
    await taskRef.delete();
  }

  // Add subtask
  void _addSubtask() {
    String subtaskTitle = _subtaskController.text;
    if (subtaskTitle.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .collection('subtasks')
          .add({
        'title': subtaskTitle,
        'is_completed': false,
        'created_at': Timestamp.now(),
      });
      _subtaskController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Row(
          children: [
            Checkbox(
              value: isCompleted,
              onChanged: (value) => _toggleCompleteAllSubtasks(),
            ),
            Expanded(child: Text(title)),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteTaskAndSubtasks,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _subtaskController,
                  decoration: InputDecoration(
                    hintText: 'Add Subtask',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addSubtask,
                    ),
                  ),
                ),
                StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('tasks')
                      .doc(taskId)
                      .collection('subtasks')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const CircularProgressIndicator();
                    var subtasks = snapshot.data!.docs;
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: subtasks.length,
                      itemBuilder: (context, index) {
                        var subtask = subtasks[index];
                        return SubtaskItem(
                          taskId: taskId,
                          subtaskId: subtask.id,
                          title: subtask['title'],
                          isCompleted: subtask['is_completed'],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SubtaskItem extends StatelessWidget {
  final String taskId;
  final String subtaskId;
  final String title;
  final bool isCompleted;

  const SubtaskItem(
      {super.key,
      required this.taskId,
      required this.subtaskId,
      required this.title,
      required this.isCompleted});

  // Toggle individual subtask completion status
  void _toggleComplete() async {
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(taskId)
        .collection('subtasks')
        .doc(subtaskId)
        .update({'is_completed': !isCompleted});
  }

  // Delete individual subtask
  void _deleteSubtask() async {
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(taskId)
        .collection('subtasks')
        .doc(subtaskId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: isCompleted,
        onChanged: (value) => _toggleComplete(),
      ),
      title: Text(title),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: _deleteSubtask,
      ),
    );
  }
}

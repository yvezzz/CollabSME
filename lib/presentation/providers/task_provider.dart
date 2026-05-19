import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository.dart';

final taskRepositoryProvider = Provider((ref) => TaskRepository());

final taskListProvider = StateNotifierProvider.family<TaskListNotifier, AsyncValue<List<TaskModel>>, String>((ref, projectId) {
  return TaskListNotifier(ref.watch(taskRepositoryProvider), projectId);
});

class TaskListNotifier extends StateNotifier<AsyncValue<List<TaskModel>>> {
  final TaskRepository _repository;
  final String _projectId;

  TaskListNotifier(this._repository, this._projectId) : super(const AsyncValue.loading()) {
    fetchTasks();
  }

  Future<void> fetchTasks({bool showLoading = true}) async {
    if (showLoading) state = const AsyncValue.loading();
    try {
      final tasks = await _repository.getTasks(_projectId);
      state = AsyncValue.data(tasks);
    } catch (e, stack) {
      if (showLoading) {
        state = AsyncValue.error(e, stack);
      }
      // Rafraîchissement silencieux : on garde la liste affichée en cas d'échec réseau
    }
  }

  /// Déplace une carte vers une colonne (statut) en appelant l'API `reorder` du backend.
  Future<void> moveTask(String taskId, String newStatus) async {
    final previousState = state;
    final list = state.valueOrNull;
    if (list == null) return;

    final newOrder = list.where((t) => t.id != taskId && t.status == newStatus).length;

    state = AsyncValue.data(
      list.map((t) {
        if (t.id == taskId) return t.copyWith(status: newStatus);
        return t;
      }).toList(),
    );

    try {
      await _repository.reorderTask(_projectId, taskId, newStatus, newOrder);
      await fetchTasks(showLoading: false);
    } catch (_) {
      state = previousState;
    }
  }

  Future<void> createTaskInColumn({
    required String title,
    String description = '',
    required String status,
    String? assignedTo,
    String priority = 'MEDIUM',
    String? dueDate,
  }) async {
    final data = <String, dynamic>{
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
    };
    if (assignedTo != null) data['assigned_to'] = assignedTo;
    if (dueDate != null) data['due_date'] = dueDate;
    await _repository.createTask(_projectId, data);
    await fetchTasks(showLoading: false);
  }
}

final userTasksProvider = StateNotifierProvider<UserTasksNotifier, AsyncValue<List<TaskModel>>>((ref) {
  return UserTasksNotifier(ref.watch(taskRepositoryProvider));
});

class UserTasksNotifier extends StateNotifier<AsyncValue<List<TaskModel>>> {
  final TaskRepository _repository;

  UserTasksNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    state = const AsyncValue.loading();
    try {
      final tasks = await _repository.getUserTasks();
      state = AsyncValue.data(tasks);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

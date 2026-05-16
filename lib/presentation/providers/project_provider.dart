import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/project_model.dart';
import '../../data/models/dashboard_stats.dart';
import '../../data/repositories/project_repository.dart';

final projectRepositoryProvider = Provider((ref) => ProjectRepository());

final projectListProvider =
    StateNotifierProvider<ProjectListNotifier, AsyncValue<List<ProjectModel>>>((
      ref,
    ) {
      return ProjectListNotifier(ref.watch(projectRepositoryProvider));
    });

class ProjectListNotifier
    extends StateNotifier<AsyncValue<List<ProjectModel>>> {
  final ProjectRepository _repository;

  ProjectListNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchProjects();
  }

  Future<void> fetchProjects() async {
    state = const AsyncValue.loading();
    try {
      final projects = await _repository.getProjects();
      state = AsyncValue.data(projects);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addProject({
    required String title,
    required String description,
    String? key,
    String? priority,
    double? budget,
  }) async {
    try {
      final newProject = await _repository.createProject(
        title: title,
        description: description,
        key: key,
        priority: priority ?? 'MEDIUM',
        budget: budget,
      );
      state.whenData((projects) {
        state = AsyncValue.data([newProject, ...projects]);
      });
    } catch (e) {
      rethrow;
    }
  }
}

final dashboardStatsProvider =
    StateNotifierProvider<DashboardStatsNotifier, AsyncValue<DashboardStats>>((
      ref,
    ) {
      return DashboardStatsNotifier(ref.watch(projectRepositoryProvider));
    });

class DashboardStatsNotifier extends StateNotifier<AsyncValue<DashboardStats>> {
  final ProjectRepository _repository;

  DashboardStatsNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchStats();
  }

  Future<void> fetchStats() async {
    state = const AsyncValue.loading();
    try {
      final stats = await _repository.getDashboardStats();
      state = AsyncValue.data(stats);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final singleProjectProvider =
    StateNotifierProvider.family<
      ProjectNotifier,
      AsyncValue<ProjectModel>,
      String
    >((ref, projectId) {
      return ProjectNotifier(ref.watch(projectRepositoryProvider), projectId);
    });

class ProjectNotifier extends StateNotifier<AsyncValue<ProjectModel>> {
  final ProjectRepository _repository;
  final String projectId;

  ProjectNotifier(this._repository, this.projectId)
    : super(const AsyncValue.loading()) {
    fetchProject();
  }

  Future<void> fetchProject() async {
    state = const AsyncValue.loading();
    try {
      final project = await _repository.getProject(projectId);
      state = AsyncValue.data(project);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateProject({
    String? title,
    String? description,
    String? key,
    String? status,
    String? priority,
    double? budget,
    String? startDate,
    String? endDate,
    List<String>? tags,
  }) async {
    try {
      final updated = await _repository.updateProject(
        projectId,
        title: title,
        description: description,
        key: key,
        status: status,
        priority: priority,
        budget: budget,
        startDate: startDate,
        endDate: endDate,
        tags: tags,
      );
      state = AsyncValue.data(updated);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateStatus(String action) async {
    await _repository.updateProjectStatus(projectId, action);
    await fetchProject();
  }
}

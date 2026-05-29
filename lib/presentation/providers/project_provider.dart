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
  String _search = '';
  int _page = 1;
  int _totalCount = 0;
  bool _isLoadingMore = false;

  ProjectListNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchProjects();
  }

  bool get hasMore => _page * 20 < _totalCount;
  int get totalCount => _totalCount;
  String get searchQuery => _search;

  Future<void> fetchProjects({bool append = false}) async {
    if (append) {
      _isLoadingMore = true;
    } else {
      state = const AsyncValue.loading();
      _page = 1;
    }
    try {
      final result = await _repository.getProjects(page: _page, search: _search);
      final List<ProjectModel> projects = result['projects'];
      _totalCount = result['count'] as int;
      if (append && state.valueOrNull != null) {
        state = AsyncValue.data([...state.valueOrNull!, ...projects]);
      } else {
        state = AsyncValue.data(projects);
      }
    } catch (e, stack) {
      if (!append) state = AsyncValue.error(e, stack);
    } finally {
      _isLoadingMore = false;
    }
  }

  void search(String query) {
    _search = query;
    _page = 1;
    fetchProjects();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;
    _page++;
    await fetchProjects(append: true);
  }

  void refresh() {
    _page = 1;
    _search = '';
    fetchProjects();
  }

  Future<void> addProject({
    required String title,
    required String description,
    String? key,
    String? priority,
    double? budget,
    String? startDate,
    String? endDate,
    int? leadId,
    List<int>? memberIds,
  }) async {
    try {
      final newProject = await _repository.createProject(
        title: title,
        description: description,
        key: key,
        priority: priority ?? 'MEDIUM',
        budget: budget,
        startDate: startDate,
        endDate: endDate,
        leadId: leadId,
        memberIds: memberIds,
      );
      state.whenData((projects) {
        state = AsyncValue.data([newProject, ...projects]);
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createFromTemplate({
    required String templateId,
    required String title,
  }) async {
    try {
      final newProject = await _repository.createFromTemplate(templateId, title);
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

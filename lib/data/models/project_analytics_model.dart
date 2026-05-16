class ProjectAnalyticsModel {
  final int totalTasks;
  final double completionRate;
  final Map<String, int> tasksByStatus;
  final List<MemberTaskCount> tasksPerMember;
  final int overdueTasks;

  ProjectAnalyticsModel({
    required this.totalTasks,
    required this.completionRate,
    required this.tasksByStatus,
    required this.tasksPerMember,
    required this.overdueTasks,
  });

  factory ProjectAnalyticsModel.fromJson(Map<String, dynamic> json) {
    var statusMap = <String, int>{};
    if (json['tasks_by_status'] != null) {
      (json['tasks_by_status'] as Map).forEach((k, v) {
        statusMap[k.toString()] = v as int;
      });
    }

    var memberTasks = <MemberTaskCount>[];
    if (json['tasks_per_member'] != null) {
      memberTasks = (json['tasks_per_member'] as List)
          .map((item) => MemberTaskCount.fromJson(item))
          .toList();
    }

    return ProjectAnalyticsModel(
      totalTasks: json['total_tasks'] ?? 0,
      completionRate: (json['completion_rate'] ?? 0).toDouble(),
      tasksByStatus: statusMap,
      tasksPerMember: memberTasks,
      overdueTasks: json['overdue_tasks'] ?? 0,
    );
  }
}

class MemberTaskCount {
  final String userName;
  final int count;

  MemberTaskCount({required this.userName, required this.count});

  factory MemberTaskCount.fromJson(Map<String, dynamic> json) {
    return MemberTaskCount(
      userName: json['user'] ?? 'Inconnu',
      count: json['count'] ?? 0,
    );
  }
}

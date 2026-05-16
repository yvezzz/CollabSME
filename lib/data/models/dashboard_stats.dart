class DashboardStats {
  final int totalProjects;
  final int activeTasks;
  final int teamMembers;

  DashboardStats({
    required this.totalProjects,
    required this.activeTasks,
    required this.teamMembers,
  });

  factory DashboardStats.empty() => DashboardStats(totalProjects: 0, activeTasks: 0, teamMembers: 0);
}

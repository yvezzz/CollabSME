import 'package:flutter/material.dart';
import '../../presentation/screens/public/features_screen.dart';
import '../../presentation/screens/public/contact_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/home/ai_assistant_screen.dart';
import '../../presentation/screens/home/company_settings_screen.dart';
import '../../presentation/screens/home/team_screen.dart';
import '../../presentation/screens/projects/add_project_screen.dart';
import '../../presentation/screens/projects/project_details_screen.dart';
import '../../presentation/screens/projects/project_members_screen.dart';
import '../../presentation/screens/tasks/task_board_screen.dart';
import '../../presentation/screens/tasks/task_create_screen.dart';
import '../../presentation/screens/tasks/task_detail_screen.dart';
import '../../presentation/screens/activity/activity_log_screen.dart';

class Routes {
  static const String features = '/features';
  static const String contact = '/contact';
  static const String login = '/login';
  static const String register = '/register';
  static const String aiAssistant = '/ai-assistant';
  static const String companySettings = '/company-settings';
  static const String projectCreate = '/projects/create';
  static const String projectDetails = '/projects';
  static const String projectMembers = '/projects/members';
  static const String taskBoard = '/tasks/board';
  static const String taskCreate = '/tasks/create';
  static const String taskDetail = '/tasks/detail';
  static const String activityLog = '/activity';
  static const String team = '/team';
}

Route<dynamic>? generateRoute(RouteSettings settings) {
  final name = settings.name ?? '';

  switch (name) {
    case Routes.projectCreate:
      return MaterialPageRoute(builder: (_) => const AddProjectScreen(), settings: settings);
    case Routes.features:
      return MaterialPageRoute(builder: (_) => const FeaturesScreen(), settings: settings);
    case Routes.contact:
      return MaterialPageRoute(builder: (_) => const ContactScreen(), settings: settings);
    case Routes.login:
      return MaterialPageRoute(builder: (_) => const LoginScreen(), settings: settings);
    case Routes.register:
      return MaterialPageRoute(builder: (_) => const RegisterScreen(), settings: settings);
    case Routes.aiAssistant:
      return MaterialPageRoute(builder: (_) => const AIAssistantScreen(), settings: settings);
    case Routes.companySettings:
      return MaterialPageRoute(builder: (_) => const CompanySettingsScreen(), settings: settings);
    case Routes.team:
      return MaterialPageRoute(builder: (_) => const TeamScreen(), settings: settings);
  }

  if (name.startsWith('${Routes.projectDetails}/')) {
    final projectId = name.split('/').last;
    return MaterialPageRoute(builder: (_) => ProjectDetailsScreen(projectId: projectId), settings: settings);
  }
  if (name.startsWith('${Routes.projectMembers}/')) {
    final projectId = name.split('/').last;
    return MaterialPageRoute(builder: (_) => ProjectMembersScreen(projectId: projectId), settings: settings);
  }
  if (name.startsWith('${Routes.taskCreate}/')) {
    final parts = name.split('/');
    final projectId = parts.length >= 4 ? parts[3] : (settings.arguments as String? ?? '');
    return MaterialPageRoute(builder: (_) => TaskCreateScreen(projectId: projectId), settings: settings);
  }
  if (name.startsWith('${Routes.taskBoard}/')) {
    final parts = name.split('/');
    final projectId = parts.length >= 4 ? parts[3] : (settings.arguments as String? ?? '');
    return MaterialPageRoute(builder: (_) => TaskBoardScreen(projectId: projectId, projectName: 'Projet'), settings: settings);
  }
  if (name.startsWith('${Routes.taskDetail}/')) {
    final parts = name.split('/');
    if (parts.length >= 5) {
      final projectId = parts[3];
      final taskId = parts[4];
      return MaterialPageRoute(builder: (_) => TaskDetailScreen(projectId: projectId, taskId: taskId), settings: settings);
    }
  }
  if (name.startsWith('${Routes.activityLog}/')) {
    final projectId = name.split('/').last;
    return MaterialPageRoute(builder: (_) => ActivityLogScreen(projectId: projectId), settings: settings);
  }

  return null;
}

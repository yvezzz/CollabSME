import 'package:flutter_test/flutter_test.dart';
import 'package:collabsme/data/models/user_model.dart';
import 'package:collabsme/data/models/notification_model.dart';
import 'package:collabsme/data/models/project_model.dart';
import 'package:collabsme/data/models/task_model.dart';
import 'package:collabsme/data/models/activity_log_model.dart';
import 'package:collabsme/data/models/project_member_model.dart';
import 'package:collabsme/data/models/attachment_model.dart';
import 'package:collabsme/data/models/company_model.dart';
import 'package:collabsme/data/models/dashboard_stats.dart';
import 'package:collabsme/data/models/project_analytics_model.dart';
import 'package:collabsme/data/models/ai_models.dart';

void main() {
  group('UserModel', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': '123',
        'email': 'test@example.com',
        'first_name': 'Jean',
        'last_name': 'Dupont',
        'phone_number': '+33123456789',
        'company': '456',
        'role': 'ADMIN',
        'is_company_admin': true,
        'avatar_url': 'https://example.com/avatar.png',
        'bio': 'Développeur',
      };
      final user = UserModel.fromJson(json);
      expect(user.id, '123');
      expect(user.email, 'test@example.com');
      expect(user.firstName, 'Jean');
      expect(user.lastName, 'Dupont');
      expect(user.fullName, 'Jean Dupont');
      expect(user.companyId, '456');
      expect(user.role, 'ADMIN');
      expect(user.isCompanyAdmin, isTrue);
      expect(user.avatarUrl, 'https://example.com/avatar.png');
      expect(user.bio, 'Développeur');
      expect(user.displayRole, 'Admin');
    });

    test('fromJson handles missing optional fields', () {
      final json = {'id': '123', 'email': 'test@example.com', 'first_name': '', 'last_name': ''};
      final user = UserModel.fromJson(json);
      expect(user.fullName, 'test');
      expect(user.phoneNumber, isNull);
      expect(user.companyId, isNull);
      expect(user.role, 'MEMBER');
      expect(user.isCompanyAdmin, isFalse);
    });

    test('toJson produces valid map', () {
      final user = UserModel(id: '1', email: 'a@b.com', firstName: 'Alice', lastName: 'Bob', role: 'LEAD');
      final json = user.toJson();
      expect(json['email'], 'a@b.com');
      expect(json['role'], 'LEAD');
    });
  });

  group('NotificationModel', () {
    test('fromJson with all fields', () {
      final json = {
        'id': 'n1', 'title': 'Tâche assignée', 'message': 'Nouvelle tâche',
        'notification_type': 'TASK_ASSIGNED', 'is_read': false,
        'related_id': 'proj-123', 'created_at': '2026-05-16T12:00:00Z',
      };
      final n = NotificationModel.fromJson(json);
      expect(n.id, 'n1');
      expect(n.type, 'TASK_ASSIGNED');
      expect(n.relatedId, 'proj-123');
      expect(n.isRead, isFalse);
    });

    test('fromJson with minimal fields', () {
      final json = {'id': 'n2', 'notification_type': 'COMMENT', 'is_read': true, 'created_at': '2026-05-16T12:00:00Z'};
      final n = NotificationModel.fromJson(json);
      expect(n.relatedId, isNull);
      expect(n.isRead, isTrue);
    });

    test('copyWith preserves unrelated fields', () {
      final n = NotificationModel(id: 'n1', type: 'TASK_ASSIGNED', title: 'Titre', message: 'Msg', isRead: false, createdAt: DateTime(2026, 5, 16));
      final n2 = n.copyWith(isRead: true);
      expect(n2.isRead, isTrue);
      expect(n2.title, 'Titre');
      expect(n2.id, 'n1');
    });
  });

  group('ProjectModel', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'p1', 'title': 'Projet Test', 'description': 'Desc', 'status': 'ACTIVE',
        'priority': 'HIGH', 'task_completion_percentage': 75.0, 'member_count': 3,
        'budget': '100000', 'actual_cost': '50000', 'tags': ['dev'],
        'created_at': '2026-01-01T00:00:00Z', 'start_date': '2026-01-15T00:00:00Z',
      };
      final p = ProjectModel.fromJson(json);
      expect(p.id, 'p1');
      expect(p.status, 'ACTIVE');
      expect(p.progress, 0.75);
      expect(p.memberCount, 3);
      expect(p.budget, 100000);
      expect(p.tags, ['dev']);
    });

    test('fromJson handles minimal fields', () {
      final json = {'id': 'p1', 'title': 'Minimal'};
      final p = ProjectModel.fromJson(json);
      expect(p.status, 'PLANNING');
      expect(p.progress, 0.0);
      expect(p.budget, isNull);
    });

    test('toJson round-trip', () {
      final p = ProjectModel(id: 'p1', title: 'Test', description: 'Desc', status: 'ACTIVE', priority: 'HIGH', progress: 0.5, memberCount: 2, createdAt: DateTime(2026, 1, 1));
      final p2 = ProjectModel.fromJson(p.toJson());
      expect(p2.title, 'Test');
      expect(p2.progress, 0.5);
    });

    test('copyWith works', () {
      final p = ProjectModel(id: 'p1', title: 'Original', description: 'Desc', status: 'DRAFT', priority: 'LOW', createdAt: DateTime(2026, 1, 1));
      final p2 = p.copyWith(title: 'Modifié', status: 'ACTIVE');
      expect(p2.title, 'Modifié');
      expect(p2.status, 'ACTIVE');
      expect(p2.description, 'Desc');
    });
  });

  group('TaskModel', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 't1', 'public_id': 'TASK-001', 'project': 'p1', 'title': 'Login',
        'description': 'Page login', 'status': 'IN_PROGRESS', 'priority': 'HIGH',
        'assigned_to': 'u1', 'assigned_to_name': 'Jean Dupont',
        'created_at': '2026-05-01T08:00:00Z', 'due_date': '2026-05-15T17:00:00Z',
        'estimated_hours': 8, 'actual_hours': 6.5, 'tags': ['frontend'],
        'custom_fields': <String, dynamic>{},
        'checklist_items': [{'id': 'c1', 'title': 'Valider', 'is_completed': true, 'order': 0}],
        'comments': [{'id': 'cm1', 'content': 'OK', 'author_name': 'Moi', 'created_at': '2026-05-01T10:00:00Z'}],
        'sub_tasks_count': 1, 'comments_count': 1, 'attachments_count': 0,
      };
      final t = TaskModel.fromJson(json);
      expect(t.id, 't1');
      expect(t.publicId, 'TASK-001');
      expect(t.status, 'IN_PROGRESS');
      expect(t.priority, 'HIGH');
      expect(t.assignedTo, 'u1');
      expect(t.checklistItems.length, 1);
      expect(t.comments.length, 1);
    });

    test('fromJson handles minimal fields', () {
      final json = {'title': 'Quick', 'status': 'TODO', 'priority': 'MEDIUM', 'created_at': '2026-05-01T08:00:00Z'};
      final t = TaskModel.fromJson(json);
      expect(t.description, '');
      expect(t.assignedTo, isNull);
      expect(t.checklistItems, isEmpty);
    });

    test('copyWith works', () {
      final t = TaskModel(id: 't1', title: 'Original', description: 'Desc', status: 'TODO', priority: 'LOW', createdAt: DateTime(2026, 1, 1));
      final t2 = t.copyWith(title: 'Modifié', status: 'DONE', priority: 'HIGH');
      expect(t2.title, 'Modifié');
      expect(t2.status, 'DONE');
      expect(t2.description, 'Desc');
    });
  });

  group('ActivityLogModel', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'a1', 'actor_name': 'Jean Dupont', 'actor_avatar': 'https://pic.png',
        'action_type': 'TASK_CREATED', 'target_description': 'Nouvelle tâche',
        'timestamp': '2026-05-16T12:00:00Z', 'metadata': {'project_id': 'p1'},
      };
      final a = ActivityLogModel.fromJson(json);
      expect(a.id, 'a1');
      expect(a.actorName, 'Jean Dupont');
      expect(a.actorAvatar, 'https://pic.png');
      expect(a.actionType, 'TASK_CREATED');
    });

    test('fromJson handles defaults', () {
      final json = {'timestamp': '2026-05-16T12:00:00Z'};
      final a = ActivityLogModel.fromJson(json);
      expect(a.actorName, 'Système');
      expect(a.description, '');
    });
  });

  group('ProjectMemberModel', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'pm1', 'user': 'u1', 'user_email': 'test@test.com',
        'user_first_name': 'Jean', 'user_last_name': 'Dupont',
        'user_avatar': 'https://pic.png', 'role': 'LEAD',
        'joined_at': '2026-01-01T00:00:00Z',
      };
      final pm = ProjectMemberModel.fromJson(json);
      expect(pm.id, 'pm1');
      expect(pm.userId, 'u1');
      expect(pm.userEmail, 'test@test.com');
      expect(pm.userFullName, 'Jean Dupont');
      expect(pm.userAvatar, 'https://pic.png');
      expect(pm.role, 'LEAD');
    });

    test('fromJson handles missing fields', () {
      final json = {'joined_at': '2026-01-01T00:00:00Z'};
      final pm = ProjectMemberModel.fromJson(json);
      expect(pm.id, '');
      expect(pm.userId, '');
      expect(pm.role, 'MEMBER');
      expect(pm.userFullName, '');
    });
  });

  group('AttachmentModel', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'att1', 'original_filename': 'doc.pdf', 'file': 'https://url',
        'file_size': 2048,
        'uploaded_by_details': {'full_name': 'Jean Dupont'},
        'uploaded_at': '2026-05-16T12:00:00Z',
      };
      final a = AttachmentModel.fromJson(json);
      expect(a.id, 'att1');
      expect(a.fileName, 'doc.pdf');
      expect(a.fileSize, 2048);
      expect(a.uploadedBy, 'Jean Dupont');
      expect(a.sizeReadable, '2.0 KB');
    });

    test('fromJson handles defaults', () {
      final json = {'uploaded_at': '2026-05-16T12:00:00Z', 'file': ''};
      final a = AttachmentModel.fromJson(json);
      expect(a.fileName, 'Fichier');
      expect(a.uploadedBy, 'Inconnu');
      expect(a.fileSize, 0);
      expect(a.sizeReadable, '0 B');
    });

    test('sizeReadable formats bytes', () {
      final a = AttachmentModel(id: '1', fileName: 'f', fileUrl: '', fileSize: 1048576, uploadedBy: 'u', uploadedAt: DateTime(2026, 1, 1));
      expect(a.sizeReadable, '1.0 MB');
    });
  });

  group('Company', () {
    test('fromJson parses all fields', () {
      final json = {'id': 1, 'name': 'Acme Inc', 'created_at': '2026-01-01T00:00:00Z', 'subscription_status': 'active'};
      final c = Company.fromJson(json);
      expect(c.id, 1);
      expect(c.name, 'Acme Inc');
      expect(c.subscriptionStatus, 'active');
    });

    test('fromJson handles missing optional fields', () {
      final json = {'id': 2, 'name': 'Startup', 'created_at': '2026-01-01T00:00:00Z'};
      final c = Company.fromJson(json);
      expect(c.subscriptionStatus, isNull);
    });

    test('toJson round-trip', () {
      final c = Company(id: 1, name: 'Acme', createdAt: DateTime(2026, 1, 1), subscriptionStatus: 'trial');
      final c2 = Company.fromJson(c.toJson());
      expect(c2.name, 'Acme');
      expect(c2.subscriptionStatus, 'trial');
    });
  });

  group('DashboardStats', () {
    test('empty factory creates zero values', () {
      final s = DashboardStats.empty();
      expect(s.totalProjects, 0);
      expect(s.activeTasks, 0);
      expect(s.teamMembers, 0);
    });

    test('constructor assigns values', () {
      final s = DashboardStats(totalProjects: 5, activeTasks: 12, teamMembers: 8);
      expect(s.totalProjects, 5);
      expect(s.activeTasks, 12);
      expect(s.teamMembers, 8);
    });
  });

  group('ProjectAnalyticsModel', () {
    test('fromJson parses all fields', () {
      final json = {
        'total_tasks': 20, 'completion_rate': 50.0, 'overdue_tasks': 3,
        'tasks_by_status': {'TODO': 5, 'DONE': 10, 'IN_PROGRESS': 5},
        'tasks_per_member': [
          {'user': 'Jean', 'count': 10},
          {'user': 'Marie', 'count': 8},
        ],
      };
      final a = ProjectAnalyticsModel.fromJson(json);
      expect(a.totalTasks, 20);
      expect(a.completionRate, 50.0);
      expect(a.overdueTasks, 3);
      expect(a.tasksByStatus['TODO'], 5);
      expect(a.tasksPerMember.length, 2);
      expect(a.tasksPerMember.first.userName, 'Jean');
    });

    test('fromJson handles empty data', () {
      final json = <String, dynamic>{};
      final a = ProjectAnalyticsModel.fromJson(json);
      expect(a.totalTasks, 0);
      expect(a.completionRate, 0.0);
      expect(a.tasksByStatus, isEmpty);
      expect(a.tasksPerMember, isEmpty);
    });
  });

  group('AI Models', () {
    test('AIPredictionModel fromJson', () {
      final json = <String, dynamic>{
        'id': 1, 'task': 10, 'risk_percentage': 75.0, 'predicted_delay_days': 5,
        'confidence': 0.85, 'reasons': <String, dynamic>{'complexity': 'high'},
        'recommendations': <String, dynamic>{'action': 'review'},
        'created_at': '2026-05-16T12:00:00Z', 'is_resolved': false,
      };
      final m = AIPredictionModel.fromJson(json);
      expect(m.id, 1);
      expect(m.riskPercentage, 75.0);
      expect(m.confidence, 0.85);
      expect(m.isResolved, isFalse);
      expect(m.recommendations['action'], 'review');
    });

    test('AIPredictionModel handles defaults', () {
      final json = <String, dynamic>{'id': 1, 'task': 1, 'reasons': <String, dynamic>{}, 'recommendations': <String, dynamic>{}, 'created_at': '2026-01-01T00:00:00Z'};
      final m = AIPredictionModel.fromJson(json);
      expect(m.riskPercentage, 0.0);
      expect(m.confidence, 0.0);
      expect(m.isResolved, isFalse);
      expect(m.predictedDelayDays, isNull);
    });

    test('AIPredictionModel toJson round-trip', () {
      final m = AIPredictionModel(id: 1, taskId: 10, riskPercentage: 80.0, confidence: 0.9, reasons: <String, dynamic>{'a': 'b'}, recommendations: <String, dynamic>{'c': 'd'}, createdAt: DateTime(2026, 1, 1), isResolved: true);
      final m2 = AIPredictionModel.fromJson(m.toJson());
      expect(m2.riskPercentage, 80.0);
      expect(m2.isResolved, isTrue);
    });

    test('AIGenerationLogModel fromJson', () {
      final json = {
        'id': 1, 'user': 5, 'task': 10, 'prompt': 'Générer', 'response': 'Réponse',
        'model_used': 'gpt-4', 'created_at': '2026-05-16T12:00:00Z',
      };
      final m = AIGenerationLogModel.fromJson(json);
      expect(m.id, 1);
      expect(m.prompt, 'Générer');
      expect(m.response, 'Réponse');
      expect(m.modelUsed, 'gpt-4');
    });

    test('AIGenerationLogModel toJson round-trip', () {
      final m = AIGenerationLogModel(id: 1, userId: 5, taskId: 10, prompt: 'P', response: 'R', modelUsed: 'gpt-4', createdAt: DateTime(2026, 1, 1));
      final m2 = AIGenerationLogModel.fromJson(m.toJson());
      expect(m2.prompt, 'P');
      expect(m2.modelUsed, 'gpt-4');
    });

    test('AISentimentAnalysisModel fromJson', () {
      final json = {
        'id': 1, 'user': 5, 'project': 2,
        'sentiment_score': 0.75, 'fatigue_score': 0.2,
        'analysis_period_start': '2026-01-01T00:00:00Z',
        'analysis_period_end': '2026-01-31T00:00:00Z',
        'key_insights': {'trend': 'positive'},
      };
      final m = AISentimentAnalysisModel.fromJson(json);
      expect(m.sentimentScore, 0.75);
      expect(m.fatigueScore, 0.2);
      expect(m.keyInsights['trend'], 'positive');
    });

    test('AISentimentAnalysisModel handles defaults', () {
      final json = {
        'id': 1, 'user': 1, 'project': 1,
        'analysis_period_start': '2026-01-01T00:00:00Z',
        'analysis_period_end': '2026-01-31T00:00:00Z',
      };
      final m = AISentimentAnalysisModel.fromJson(json);
      expect(m.sentimentScore, 0.0);
      expect(m.fatigueScore, 0.0);
      expect(m.keyInsights, isEmpty);
    });

    test('AIBlockageDetectionModel fromJson', () {
      final json = {
        'id': 1, 'task': 10, 'detection_type': 'BLOCKED',
        'trigger_comment': 3, 'confidence': 0.9,
        'suggested_actions': {'unblock': 'review'},
        'detected_at': '2026-05-16T12:00:00Z',
        'resolved_at': '2026-05-17T12:00:00Z',
      };
      final m = AIBlockageDetectionModel.fromJson(json);
      expect(m.detectionType, 'BLOCKED');
      expect(m.triggerCommentId, 3);
      expect(m.confidence, 0.9);
      expect(m.resolvedAt, isNotNull);
    });

    test('AIBlockageDetectionModel handles defaults', () {
      final json = {'id': 1, 'task': 1, 'detection_type': 'WARNING', 'detected_at': '2026-01-01T00:00:00Z'};
      final m = AIBlockageDetectionModel.fromJson(json);
      expect(m.confidence, 0.0);
      expect(m.resolvedAt, isNull);
      expect(m.triggerCommentId, isNull);
    });
  });
}

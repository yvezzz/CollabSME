import '../../utils/safe_parser.dart';

class TaskModel {
  final String id;
  final String? publicId;
  final String? parentTask;
  final String? projectId;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String? assignedTo;
  final String? assignedToName;
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? startDate;
  final double? estimatedHours;
  final double actualHours;
  final List<String> tags;
  final Map<String, dynamic> customFields;
  final List<SubTaskModel> checklistItems;
  final List<CommentModel> comments;
  final int subTasksCount;
  final int commentsCount;
  final int attachmentsCount;

  TaskModel({
    required this.id,
    this.publicId,
    this.parentTask,
    this.projectId,
    required this.title,
    this.description = '',
    required this.status,
    required this.priority,
    this.assignedTo,
    this.assignedToName,
    required this.createdAt,
    this.dueDate,
    this.startDate,
    this.estimatedHours,
    this.actualHours = 0.0,
    this.tags = const [],
    this.customFields = const {},
    this.checklistItems = const [],
    this.comments = const [],
    this.subTasksCount = 0,
    this.commentsCount = 0,
    this.attachmentsCount = 0,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id']?.toString() ?? '',
      publicId: json['public_id']?.toString(),
      parentTask: json['parent_task']?.toString(),
      projectId: json['project']?.toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'TODO',
      priority: json['priority'] ?? 'MEDIUM',
      assignedTo: json['assigned_to']?.toString(),
      assignedToName: json['assigned_to_name']?.toString(),
      createdAt: SafeParser.parseDateTime(json['created_at']) ?? DateTime.now(),
      dueDate: SafeParser.parseDateTime(json['due_date']),
      startDate: SafeParser.parseDateTime(json['start_date']),
      estimatedHours: json['estimated_hours'] != null
          ? double.tryParse(json['estimated_hours'].toString())
          : null,
      actualHours: double.tryParse(json['actual_hours'].toString()) ?? 0.0,
      tags: json['tags'] is List ? List<String>.from(json['tags']) : SafeParser.parseJsonList(json['tags']),
      customFields: json['custom_fields'] is Map ? json['custom_fields'] : SafeParser.parseJsonMap(json['custom_fields']),
      checklistItems: SafeParser.parseList<SubTaskModel>(json['checklist_items'], (m) => SubTaskModel.fromJson(m)),
      comments: SafeParser.parseList<CommentModel>(json['comments'], (m) => CommentModel.fromJson(m)),
      subTasksCount: SafeParser.parseInt(json['sub_tasks_count']),
      commentsCount: SafeParser.parseInt(json['comments_count']),
      attachmentsCount: SafeParser.parseInt(json['attachments_count']),
    );
  }

  TaskModel copyWith({
    String? id,
    String? publicId,
    String? parentTask,
    String? projectId,
    String? title,
    String? description,
    String? status,
    String? priority,
    String? assignedTo,
    String? assignedToName,
    DateTime? createdAt,
    DateTime? dueDate,
    DateTime? startDate,
    double? estimatedHours,
    double? actualHours,
    List<String>? tags,
    Map<String, dynamic>? customFields,
    List<SubTaskModel>? checklistItems,
    List<CommentModel>? comments,
    int? subTasksCount,
    int? commentsCount,
    int? attachmentsCount,
  }) {
    return TaskModel(
      id: id ?? this.id,
      publicId: publicId ?? this.publicId,
      parentTask: parentTask ?? this.parentTask,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      startDate: startDate ?? this.startDate,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      actualHours: actualHours ?? this.actualHours,
      tags: tags ?? this.tags,
      customFields: customFields ?? this.customFields,
      checklistItems: checklistItems ?? this.checklistItems,
      comments: comments ?? this.comments,
      subTasksCount: subTasksCount ?? this.subTasksCount,
      commentsCount: commentsCount ?? this.commentsCount,
      attachmentsCount: attachmentsCount ?? this.attachmentsCount,
    );
  }
}

class SubTaskModel {
  final String id;
  final String title;
  final bool isCompleted;
  final int order;

  SubTaskModel({
    required this.id,
    required this.title,
    required this.isCompleted,
    this.order = 0,
  });

  factory SubTaskModel.fromJson(Map<String, dynamic> json) {
    return SubTaskModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      isCompleted: json['is_completed'] == true,
      order: json['order'] is int ? json['order'] as int : int.tryParse(json['order']?.toString() ?? '0') ?? 0,
    );
  }
}

class CommentModel {
  final String id;
  final String? parent;
  final String content;
  final String authorName;
  final List<String> mentions;
  final Map<String, dynamic> reactions;
  final DateTime createdAt;
  final List<CommentModel> replies;

  CommentModel({
    required this.id,
    this.parent,
    required this.content,
    required this.authorName,
    this.mentions = const [],
    this.reactions = const {},
    required this.createdAt,
    this.replies = const [],
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id']?.toString() ?? '',
      parent: json['parent']?.toString(),
      content: json['content'] ?? '',
      authorName: json['author_name'] ?? 'Inconnu',
      mentions: json['mentions'] is List ? (json['mentions'] as List).map((e) => e.toString()).toList() : <String>[],
      reactions: json['reactions'] ?? {},
      createdAt: SafeParser.parseDateTime(json['created_at']) ?? DateTime.now(),
      replies: (json['replies'] as List? ?? [])
          .map((r) => CommentModel.fromJson(r))
          .toList(),
    );
  }
}

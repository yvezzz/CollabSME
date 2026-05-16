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
      publicId: json['public_id'],
      parentTask: json['parent_task'],
      projectId: json['project']?.toString(),
      title: json['title'],
      description: json['description'] ?? '',
      status: json['status'],
      priority: json['priority'],
      assignedTo: json['assigned_to'],
      assignedToName: json['assigned_to_name'],
      createdAt: DateTime.parse(json['created_at']),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      estimatedHours: json['estimated_hours'] != null
          ? double.tryParse(json['estimated_hours'].toString())
          : null,
      actualHours: double.tryParse(json['actual_hours'].toString()) ?? 0.0,
      tags: List<String>.from(json['tags'] ?? []),
      customFields: json['custom_fields'] ?? {},
      checklistItems: (json['checklist_items'] as List? ?? [])
          .map((s) => SubTaskModel.fromJson(s))
          .toList(),
      comments: (json['comments'] as List? ?? [])
          .map((c) => CommentModel.fromJson(c))
          .toList(),
      subTasksCount: json['sub_tasks_count'] ?? 0,
      commentsCount:
          json['comments_count'] ??
          (json['comments'] != null ? (json['comments'] as List).length : 0),
      attachmentsCount: json['attachments_count'] ?? 0,
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
      title: json['title'],
      isCompleted: json['is_completed'] ?? false,
      order: json['order'] ?? 0,
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
      parent: json['parent'],
      content: json['content'],
      authorName: json['author_name'] ?? 'Inconnu',
      mentions: List<String>.from(json['mentions'] ?? []),
      reactions: json['reactions'] ?? {},
      createdAt: DateTime.parse(json['created_at']),
      replies: (json['replies'] as List? ?? [])
          .map((r) => CommentModel.fromJson(r))
          .toList(),
    );
  }
}

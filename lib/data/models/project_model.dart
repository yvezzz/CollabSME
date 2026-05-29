import 'dart:convert';

class ProjectModel {
  final String id;
  final String? key;
  final String title;
  final String description;
  final String status;
  final String priority;
  final double progress; // 0.0 to 1.0
  final int memberCount;
  final double? budget;
  final double actualCost;
  final List<String> tags;
  final Map<String, dynamic> customFields;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;

  ProjectModel({
    required this.id,
    this.key,
    required this.title,
    this.description = '',
    this.status = 'PLANNING',
    this.priority = 'MEDIUM',
    this.progress = 0.0,
    this.memberCount = 0,
    this.budget,
    this.actualCost = 0.0,
    this.tags = const [],
    this.customFields = const {},
    required this.createdAt,
    this.startDate,
    this.endDate,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    List<String> parseTags(dynamic t) {
      if (t is List) return List<String>.from(t);
      if (t is String && t.isNotEmpty) {
        final parsed = jsonDecode(t);
        if (parsed is List) return List<String>.from(parsed);
      }
      return [];
    }

    Map<String, dynamic> parseCustomFields(dynamic cf) {
      if (cf is Map) return Map<String, dynamic>.from(cf);
      if (cf is String && cf.isNotEmpty) {
        final parsed = jsonDecode(cf);
        if (parsed is Map) return Map<String, dynamic>.from(parsed);
      }
      return {};
    }

    return ProjectModel(
      id: json['id']?.toString() ?? (throw FormatException('Missing project id')),
      key: json['key'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'PLANNING',
      priority: json['priority'] ?? 'MEDIUM',
      progress: (json['task_completion_percentage'] ?? 0.0).toDouble() / 100.0,
      memberCount: json['member_count'] ?? 0,
      budget: json['budget'] != null ? double.tryParse(json['budget'].toString()) : null,
      actualCost: double.tryParse(json['actual_cost']?.toString() ?? '0') ?? 0.0,
      tags: parseTags(json['tags']),
      customFields: parseCustomFields(json['custom_fields']),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'task_completion_percentage': progress * 100.0,
      'member_count': memberCount,
      'budget': budget,
      'actual_cost': actualCost,
      'tags': tags,
      'custom_fields': customFields,
      'created_at': createdAt.toIso8601String(),
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }

  ProjectModel copyWith({
    String? id,
    String? key,
    String? title,
    String? description,
    String? status,
    String? priority,
    double? progress,
    int? memberCount,
    double? budget,
    double? actualCost,
    List<String>? tags,
    Map<String, dynamic>? customFields,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      key: key ?? this.key,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      progress: progress ?? this.progress,
      memberCount: memberCount ?? this.memberCount,
      budget: budget ?? this.budget,
      actualCost: actualCost ?? this.actualCost,
      tags: tags ?? this.tags,
      customFields: customFields ?? this.customFields,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

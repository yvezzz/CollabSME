import '../../utils/safe_parser.dart';

class ActivityLogModel {
  final String id;
  final String actorName;
  final String? actorAvatar;
  final String actionType;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ActivityLogModel({
    required this.id,
    required this.actorName,
    this.actorAvatar,
    required this.actionType,
    required this.description,
    required this.timestamp,
    this.metadata,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: json['id']?.toString() ?? '',
      actorName: json['actor_name'] ?? 'Système',
      actorAvatar: json['actor_avatar'],
      actionType: json['action_type'] ?? 'OTHER',
      description: json['target_description'] ?? '',
      timestamp: SafeParser.parseDateTime(json['timestamp']) ?? DateTime.now(),
      metadata: json['metadata'],
    );
  }
}

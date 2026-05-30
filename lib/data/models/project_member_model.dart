import '../../utils/safe_parser.dart';

class ProjectMemberModel {
  final String id;
  final String userId;
  final String userEmail;
  final String userFullName;
  final String? userAvatar;
  final String role; // LEAD, MEMBER
  final DateTime joinedAt;

  ProjectMemberModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userFullName,
    this.userAvatar,
    required this.role,
    required this.joinedAt,
  });

  factory ProjectMemberModel.fromJson(Map<String, dynamic> json) {
    return ProjectMemberModel(
      id: json['id']?.toString() ?? '',
      userId: json['user']?.toString() ?? '',
      userEmail: json['user_email'] ?? '',
      userFullName: "${json['user_first_name'] ?? ''} ${json['user_last_name'] ?? ''}".trim(),
      userAvatar: json['user_avatar'],
      role: json['role'] ?? 'MEMBER',
      joinedAt: SafeParser.parseDateTime(json['joined_at']) ?? DateTime.now(),
    );
  }
}

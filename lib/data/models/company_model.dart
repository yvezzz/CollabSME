class Company {
  final int id;
  final String name;
  final DateTime createdAt;
  final String? subscriptionStatus;

  Company({
    required this.id,
    required this.name,
    required this.createdAt,
    this.subscriptionStatus,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      subscriptionStatus: json['subscription_status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'subscription_status': subscriptionStatus,
    };
  }
}

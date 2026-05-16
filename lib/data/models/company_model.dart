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
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
      subscriptionStatus: json['subscription_status'],
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

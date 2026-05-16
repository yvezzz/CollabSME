class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? companyId;
  final String? role;
  final bool isCompanyAdmin;
  final String? avatarUrl;
  final String? bio;

  final Map<String, dynamic>? preferences;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.companyId,
    this.role,
    this.isCompanyAdmin = false,
    this.avatarUrl,
    this.bio,
    this.preferences,
  });

  String get fullName => "$firstName $lastName".trim().isEmpty ? email.split('@')[0] : "$firstName $lastName".trim();

  String get displayRole {
    if (isCompanyAdmin) return "Admin";
    switch (role) {
      case 'LEAD':
        return "Chef d'équipe";
      case 'MEMBER':
        return "Membre";
      default:
        return role ?? "Membre";
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phoneNumber: json['phone_number'] as String?,
      companyId: json['company']?.toString(),
      role: json['role'] ?? 'MEMBER',
      isCompanyAdmin: json['is_company_admin'] == true,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      preferences: json['preferences'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'company': companyId,
      'role': role,
      'is_company_admin': isCompanyAdmin,
      'avatar_url': avatarUrl,
      'bio': bio,
      'preferences': preferences,
    };
  }
}

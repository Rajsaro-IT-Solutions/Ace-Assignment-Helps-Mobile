class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String phone;
  final String country;
  final String university;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
    this.country = '',
    this.university = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Student',
      phone: json['phone']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      university: json['university']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'country': country,
      'university': university,
    };
  }

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isStudent => role.toLowerCase() == 'student';
  bool get isAllocator => role.toLowerCase() == 'allocator';
  bool get isExpert => role.toLowerCase() == 'expert';

  String get initials {
    if (name.trim().isEmpty) return role.isNotEmpty ? role[0].toUpperCase() : 'U';
    final parts = name.trim().split(' ');
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}

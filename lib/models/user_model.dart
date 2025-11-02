// models/user_model.dart
class User {
  final int id;
  final String email;
  final String fullName;
  final String mobileNumber; // This is the actual field name from your database
  final bool isAdmin;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.mobileNumber, // Changed from 'phone' to 'mobileNumber'
    required this.isAdmin,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      mobileNumber: json['mobile_number'], // Match your database field
      isAdmin: json['is_admin'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'mobile_number': mobileNumber,
      'is_admin': isAdmin,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // For updating profile
  Map<String, dynamic> toUpdateJson() {
    return {
      'full_name': fullName,
      'mobile_number': mobileNumber,
    };
  }
}
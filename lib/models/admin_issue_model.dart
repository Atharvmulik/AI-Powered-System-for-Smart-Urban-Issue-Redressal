import 'package:flutter/material.dart'; // ✅ Add this import

class AdminIssue {
  final int id;
  final String userName;
  final String userEmail;
  final String userMobile;
  final String title;
  final String description;
  final String category;
  final String urgencyLevel;
  final String status;
  final String locationAddress;
  final String? assignedDepartment;
  final String? resolutionNotes;
  final String? resolvedBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AdminIssue({
    required this.id,
    required this.userName,
    required this.userEmail,
    required this.userMobile,
    required this.title,
    required this.description,
    required this.category,
    required this.urgencyLevel,
    required this.status,
    required this.locationAddress,
    this.assignedDepartment,
    this.resolutionNotes,
    this.resolvedBy,
    required this.createdAt,
    this.updatedAt,
  });

  factory AdminIssue.fromJson(Map<String, dynamic> json) {
    return AdminIssue(
      id: json['id'] ?? 0,
      userName: json['user_name'] ?? '',
      userEmail: json['user_email'] ?? '',
      userMobile: json['user_mobile'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Other',
      urgencyLevel: json['urgency_level'] ?? 'Medium',
      status: json['status'] ?? 'Pending',
      locationAddress: json['location_address'] ?? '',
      assignedDepartment: json['assigned_department'],
      resolutionNotes: json['resolution_notes'],
      resolvedBy: json['resolved_by'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
      'user_email': userEmail,
      'user_mobile': userMobile,
      'title': title,
      'description': description,
      'category': category,
      'urgency_level': urgencyLevel,
      'status': status,
      'location_address': locationAddress,
      'assigned_department': assignedDepartment,
      'resolution_notes': resolutionNotes,
      'resolved_by': resolvedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper method to get status color
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'in progress':
        return Colors.orange;
      case 'pending':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Helper method to get urgency color
  Color get urgencyColor {
    switch (urgencyLevel.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
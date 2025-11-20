class ReportModel {
  final String user_name;
  final String user_mobile;
  final String user_email;
  final String title;
  final String description;
  final String category;
  final String urgency_level;
  final double? location_lat;
  final double? location_long;
  final String? location_address;
  
  // NEW FIELDS FOR AUTO DEPARTMENT ASSIGNMENT
  final String? department;
  final bool? auto_assigned;
  final double? prediction_confidence;
  final DateTime? created_at;
  final String? image_path;

  ReportModel({
    required this.user_name,
    required this.user_mobile,
    required this.user_email,
    required this.title,
    required this.description,
    required this.category,
    required this.urgency_level,
    this.location_lat,
    this.location_long,
    this.location_address,
    
    // NEW PARAMETERS
    this.department,
    this.auto_assigned = false,
    this.prediction_confidence,
    this.created_at,
    this.image_path,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_name': user_name,
      'user_mobile': user_mobile,
      'user_email': user_email,
      'title': title,
      'description': description,
      'category': category,
      'urgency_level': urgency_level,
      'location_lat': location_lat,
      'location_long': location_long,
      'location_address': location_address,
      
      // NEW FIELDS IN JSON
      'department': department,
      'auto_assigned': auto_assigned,
      'prediction_confidence': prediction_confidence,
      'created_at': created_at?.toIso8601String(),
      'image_path': image_path,
    };
  }

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      user_name: json['user_name'] ?? '',
      user_mobile: json['user_mobile'] ?? '',
      user_email: json['user_email'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Other',
      urgency_level: json['urgency_level'] ?? 'Medium',
      location_lat: json['location_lat']?.toDouble(),
      location_long: json['location_long']?.toDouble(),
      location_address: json['location_address'],
      
      // NEW FIELDS FROM JSON
      department: json['department'],
      auto_assigned: json['auto_assigned'] ?? false,
      prediction_confidence: json['prediction_confidence']?.toDouble(),
      created_at: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      image_path: json['image_path'],
    );
  }

  // COPY WITH METHOD FOR UPDATING FIELDS
  ReportModel copyWith({
    String? user_name,
    String? user_mobile,
    String? user_email,
    String? title,
    String? description,
    String? category,
    String? urgency_level,
    double? location_lat,
    double? location_long,
    String? location_address,
    String? department,
    bool? auto_assigned,
    double? prediction_confidence,
    DateTime? created_at,
    String? image_path,
  }) {
    return ReportModel(
      user_name: user_name ?? this.user_name,
      user_mobile: user_mobile ?? this.user_mobile,
      user_email: user_email ?? this.user_email,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      urgency_level: urgency_level ?? this.urgency_level,
      location_lat: location_lat ?? this.location_lat,
      location_long: location_long ?? this.location_long,
      location_address: location_address ?? this.location_address,
      department: department ?? this.department,
      auto_assigned: auto_assigned ?? this.auto_assigned,
      prediction_confidence: prediction_confidence ?? this.prediction_confidence,
      created_at: created_at ?? this.created_at,
      image_path: image_path ?? this.image_path,
    );
  }

  // HELPER METHOD TO CHECK IF DEPARTMENT WAS AUTO-ASSIGNED
  bool get isAutoAssigned => auto_assigned == true;

  // HELPER METHOD TO GET PREDICTION CONFERENCE AS PERCENTAGE
  String get predictionConfidencePercent {
    if (prediction_confidence == null) return 'N/A';
    return '${prediction_confidence!.toStringAsFixed(1)}%';
  }

  // HELPER METHOD TO GET DISPLAY DEPARTMENT
  String get displayDepartment {
    return department ?? 'Not Assigned';
  }

  @override
  String toString() {
    return 'ReportModel(\n'
        '  title: $title,\n'
        '  description: $description,\n'
        '  category: $category,\n'
        '  department: $department,\n'
        '  auto_assigned: $auto_assigned,\n'
        '  prediction_confidence: $prediction_confidence,\n'
        '  urgency_level: $urgency_level\n'
        ')';
  }
}
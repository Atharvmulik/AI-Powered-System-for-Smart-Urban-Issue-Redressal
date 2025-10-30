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
    );
  }
}
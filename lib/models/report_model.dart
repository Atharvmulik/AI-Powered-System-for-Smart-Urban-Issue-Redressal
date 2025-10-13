class ReportModel {
  final String user_name;
  final String user_mobile;
  final String user_email;
  final String issue_type;
  final String title;
  final String description;
  final double? location_lat;
  final double? location_long;
  final String? location_address;

  ReportModel({
    required this.user_name,
    required this.user_mobile,
    required this.user_email,
    required this.issue_type,
    required this.title,
    required this.description,
    this.location_lat,
    this.location_long,
    this.location_address,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_name': user_name,
      'user_mobile': user_mobile,
      'user_email': user_email,
      'issue_type': issue_type,
      'title': title,
      'description': description,
      'location_lat': location_lat,
      'location_long': location_long,
      'location_address': location_address,
    };
  }

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      user_name: json['user_name'],
      user_mobile: json['user_mobile'],
      user_email: json['user_email'],
      issue_type: json['issue_type'],
      title: json['title'],
      description: json['description'],
      location_lat: json['location_lat'],
      location_long: json['location_long'],
      location_address: json['location_address'],
    );
  }
}
class AppearanceResponse {
  final int id;
  final String name;
  final String createdAt;
  final String updatedAt;

  AppearanceResponse({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppearanceResponse.fromJson(Map<String, dynamic> json) {
    return AppearanceResponse(
      id: json['id'],
      name: json['name'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
}

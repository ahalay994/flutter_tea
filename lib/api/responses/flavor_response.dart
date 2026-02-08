class FlavorResponse {
  final int id;
  final String name;
  final String createdAt;
  final String updatedAt;

  FlavorResponse({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FlavorResponse.fromJson(Map<String, dynamic> json) {
    return FlavorResponse(
      id: json['id'],
      name: json['name'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
}

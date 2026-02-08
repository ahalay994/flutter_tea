class CountryResponse {
  final int id;
  final String name;
  final String createdAt;
  final String updatedAt;

  CountryResponse({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CountryResponse.fromJson(Map<String, dynamic> json) {
    return CountryResponse(
      id: json['id'],
      name: json['name'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
}

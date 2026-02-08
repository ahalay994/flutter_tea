class TypeResponse {
  final int id;
  final String name;
  final String createdAt;
  final String updatedAt;

  TypeResponse({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TypeResponse.fromJson(Map<String, dynamic> json) {
    return TypeResponse(
      id: json['id'],
      name: json['name'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
}

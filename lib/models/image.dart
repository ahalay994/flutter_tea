class ImageModel {
  final int? id;
  final String name;
  final String status;
  final String url;
  final String? createdAt;
  final String? updatedAt;

  ImageModel({
    this.id,
    required this.name,
    required this.status,
    required this.url,
    this.createdAt,
    this.updatedAt,
  });

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      url: json['url'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
}

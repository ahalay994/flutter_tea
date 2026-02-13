class ImageResponse {
  final dynamic id;
  final String name;
  final String status;
  final String url;
  final String? createdAt;
  final String? updatedAt;

  ImageResponse({
    required this.id,
    required this.name,
    required this.status,
    required this.url,
    this.createdAt,
    this.updatedAt,
  });

  factory ImageResponse.fromJson(Map<String, dynamic> json) {
    return ImageResponse(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      url: json['url'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() => {"id": id, "name": name, "status": status, "url": url};
}

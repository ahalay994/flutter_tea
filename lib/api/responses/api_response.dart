class ApiResponse {
  final List<dynamic>? data;
  final String? message;
  final bool ok;

  ApiResponse({
    this.data,
    this.message,
    required this.ok,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      data: json['data'] as List<dynamic>?,
      message: json['message'] as String?,
      ok: json['ok'] ?? false,
    );
  }
}

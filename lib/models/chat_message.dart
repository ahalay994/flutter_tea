class ChatMessage {
  final String id;
  final String content;
  final String role; // 'user' или 'assistant'
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    String? role,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
  };
  
  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: DateTime.now().millisecondsSinceEpoch.toString(), // Используем временный ID
    role: json['role'],
    content: json['content'],
    timestamp: DateTime.now(),
  );
}
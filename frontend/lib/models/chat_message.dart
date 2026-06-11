class ChatMessage {
  final String id;
  final String userId;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  bool get isUser => role == 'user';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'role': role,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

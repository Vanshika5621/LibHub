import 'book.dart';

class Reserve {
  final String id;
  final String userId;
  final String bookId;
  final int queuePosition;
  final String status;
  final DateTime? estimatedDate;
  final bool notified;
  final DateTime? expiresAt;
  final Book? book; // Joined object

  Reserve({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.queuePosition,
    required this.status,
    this.estimatedDate,
    required this.notified,
    this.expiresAt,
    this.book,
  });

  factory Reserve.fromJson(Map<String, dynamic> json) {
    return Reserve(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bookId: json['book_id'] as String,
      queuePosition: json['queue_position'] as int? ?? 1,
      status: json['status'] as String? ?? 'waiting',
      estimatedDate: json['estimated_date'] != null ? DateTime.parse(json['estimated_date'] as String) : null,
      notified: json['notified'] as bool? ?? false,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
      book: json['books'] != null ? Book.fromJson(json['books'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'book_id': bookId,
      'queue_position': queuePosition,
      'status': status,
      'estimated_date': estimatedDate?.toIso8601String(),
      'notified': notified,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }
}

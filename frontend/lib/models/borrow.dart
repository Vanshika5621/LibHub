import 'book.dart';

class Borrow {
  final String id;
  final String userId;
  final String bookId;
  final DateTime borrowedAt;
  final DateTime dueDate;
  final DateTime? returnedAt;
  final String status;
  final int renewalCount;
  final int maxRenewals;
  final Book? book; // Joined object

  Borrow({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.borrowedAt,
    required this.dueDate,
    this.returnedAt,
    required this.status,
    required this.renewalCount,
    required this.maxRenewals,
    this.book,
  });

  bool get isOverdue => status == 'overdue' || (status == 'active' && dueDate.isBefore(DateTime.now()));

  factory Borrow.fromJson(Map<String, dynamic> json) {
    return Borrow(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bookId: json['book_id'] as String,
      borrowedAt: DateTime.parse(json['borrowed_at'] as String),
      dueDate: DateTime.parse(json['due_date'] as String),
      returnedAt: json['returned_at'] != null ? DateTime.parse(json['returned_at'] as String) : null,
      status: json['status'] as String? ?? 'active',
      renewalCount: json['renewal_count'] as int? ?? 0,
      maxRenewals: json['max_renewals'] as int? ?? 2,
      book: json['books'] != null ? Book.fromJson(json['books'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'book_id': bookId,
      'borrowed_at': borrowedAt.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'returned_at': returnedAt?.toIso8601String(),
      'status': status,
      'renewal_count': renewalCount,
      'max_renewals': maxRenewals,
    };
  }
}

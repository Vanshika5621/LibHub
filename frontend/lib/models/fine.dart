import 'borrow.dart';

class Fine {
  final String id;
  final String userId;
  final String borrowId;
  final double amount;
  final int daysOverdue;
  final double ratePerDay;
  final bool paid;
  final DateTime? paidAt;
  final bool waived;
  final DateTime createdAt;
  final Borrow? borrow; // Joined object

  Fine({
    required this.id,
    required this.userId,
    required this.borrowId,
    required this.amount,
    required this.daysOverdue,
    required this.ratePerDay,
    required this.paid,
    this.paidAt,
    required this.waived,
    required this.createdAt,
    this.borrow,
  });

  factory Fine.fromJson(Map<String, dynamic> json) {
    return Fine(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      borrowId: json['borrow_id'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      daysOverdue: json['days_overdue'] as int? ?? 0,
      ratePerDay: (json['rate_per_day'] as num?)?.toDouble() ?? 10.0,
      paid: json['paid'] as bool? ?? false,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at'] as String) : null,
      waived: json['waived'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      borrow: json['borrows'] != null ? Borrow.fromJson(json['borrows'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'borrow_id': borrowId,
      'amount': amount,
      'days_overdue': daysOverdue,
      'rate_per_day': ratePerDay,
      'paid': paid,
      'paid_at': paidAt?.toIso8601String(),
      'waived': waived,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

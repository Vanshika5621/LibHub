class Payment {
  final String id;
  final String userId;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final double amount;
  final String currency;
  final String paymentType; // 'membership' or 'fine'
  final String status; // 'pending', 'completed', 'failed', 'refunded'
  final String? membershipTier;
  final String? fineId;
  final String? receiptUrl;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.userId,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    required this.amount,
    required this.currency,
    required this.paymentType,
    required this.status,
    this.membershipTier,
    this.fineId,
    this.receiptUrl,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      razorpayOrderId: json['razorpay_order_id'] as String?,
      razorpayPaymentId: json['razorpay_payment_id'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'INR',
      paymentType: json['payment_type'] as String,
      status: json['status'] as String? ?? 'pending',
      membershipTier: json['membership_tier'] as String?,
      fineId: json['fine_id'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'amount': amount,
      'currency': currency,
      'payment_type': paymentType,
      'status': status,
      'membership_tier': membershipTier,
      'fine_id': fineId,
      'receipt_url': receiptUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

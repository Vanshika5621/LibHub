class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final bool read;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.read,
    this.metadata,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      read: json['read'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      'read': read,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class NotificationPreferences {
  final String id;
  final String userId;
  final bool dueAlerts;
  final bool reserveAlerts;
  final bool paymentAlerts;
  final bool systemAlerts;
  final String? quietHoursStart;
  final String? quietHoursEnd;

  NotificationPreferences({
    required this.id,
    required this.userId,
    required this.dueAlerts,
    required this.reserveAlerts,
    required this.paymentAlerts,
    required this.systemAlerts,
    this.quietHoursStart,
    this.quietHoursEnd,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      dueAlerts: json['due_alerts'] as bool? ?? true,
      reserveAlerts: json['reserve_alerts'] as bool? ?? true,
      paymentAlerts: json['payment_alerts'] as bool? ?? true,
      systemAlerts: json['system_alerts'] as bool? ?? true,
      quietHoursStart: json['quiet_hours_start'] as String?,
      quietHoursEnd: json['quiet_hours_end'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'due_alerts': dueAlerts,
      'reserve_alerts': reserveAlerts,
      'payment_alerts': paymentAlerts,
      'system_alerts': systemAlerts,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
    };
  }
}

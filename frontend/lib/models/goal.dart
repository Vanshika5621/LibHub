class ReadingGoal {
  final String id;
  final String userId;
  final int year;
  final int yearlyGoal;
  final int monthlyGoal;
  final int booksReadYear;
  final int booksReadMonth;
  final int currentMonth;

  ReadingGoal({
    required this.id,
    required this.userId,
    required this.year,
    required this.yearlyGoal,
    required this.monthlyGoal,
    required this.booksReadYear,
    required this.booksReadMonth,
    required this.currentMonth,
  });

  double get yearlyProgress => yearlyGoal > 0 ? (booksReadYear / yearlyGoal).clamp(0.0, 1.0) : 0.0;
  double get monthlyProgress => monthlyGoal > 0 ? (booksReadMonth / monthlyGoal).clamp(0.0, 1.0) : 0.0;

  factory ReadingGoal.fromJson(Map<String, dynamic> json) {
    return ReadingGoal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      year: json['year'] as int,
      yearlyGoal: json['yearly_goal'] as int? ?? 12,
      monthlyGoal: json['monthly_goal'] as int? ?? 1,
      booksReadYear: json['books_read_year'] as int? ?? 0,
      booksReadMonth: json['books_read_month'] as int? ?? 0,
      currentMonth: json['current_month'] as int? ?? DateTime.now().month,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'year': year,
      'yearly_goal': yearlyGoal,
      'monthly_goal': monthlyGoal,
      'books_read_year': booksReadYear,
      'books_read_month': booksReadMonth,
      'current_month': currentMonth,
    };
  }
}

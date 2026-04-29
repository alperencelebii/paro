
class RecurringExpenseModel {
  const RecurringExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.frequency,
    required this.nextPaymentDate,
    this.category = 'Subscription',
    this.isActive = true,
    this.createdAt,
  });

  final String id;
  final String title;
  final double amount;
  final String frequency;
  final DateTime nextPaymentDate;
  final String category;
  final bool isActive;
  final DateTime? createdAt;

  RecurringExpenseModel copyWith({
    String? id,
    String? title,
    double? amount,
    String? frequency,
    DateTime? nextPaymentDate,
    String? category,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return RecurringExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  double get monthlyEstimate {
    switch (frequency) {
      case 'Weekly':
        return amount * 4.33;
      case 'Yearly':
        return amount / 12;
      case 'Monthly':
      default:
        return amount;
    }
  }

  int get daysUntilDue {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dueOnly = DateTime(
      nextPaymentDate.year,
      nextPaymentDate.month,
      nextPaymentDate.day,
    );
    return dueOnly.difference(todayOnly).inDays;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'frequency': frequency,
      'nextPaymentDate': nextPaymentDate.toIso8601String(),
      'category': category,
      'isActive': isActive,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory RecurringExpenseModel.fromJson(Map<String, dynamic> json) {
    return RecurringExpenseModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      frequency: json['frequency'] as String? ?? 'Monthly',
      nextPaymentDate: DateTime.tryParse(
            json['nextPaymentDate'] as String? ?? '',
          ) ??
          DateTime.now(),
      category: json['category'] as String? ?? 'Subscription',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}


class SavingsGoalModel {
  const SavingsGoalModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    this.deadline,
    this.createdAt,
  });

  final String id;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final DateTime? deadline;
  final DateTime? createdAt;

  double get progress {
    if (targetAmount <= 0) return 0;
    return (savedAmount / targetAmount).clamp(0.0, 1.0).toDouble();
  }

  double get remainingAmount => (targetAmount - savedAmount).clamp(0.0, targetAmount).toDouble();

  int? get daysRemaining {
    if (deadline == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(deadline!.year, deadline!.month, deadline!.day);
    return end.difference(today).inDays;
  }

  SavingsGoalModel copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? savedAmount,
    DateTime? deadline,
    bool clearDeadline = false,
    DateTime? createdAt,
  }) {
    return SavingsGoalModel(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      deadline: clearDeadline ? null : deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'deadline': deadline?.toIso8601String(),
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory SavingsGoalModel.fromJson(Map<String, dynamic> json) {
    return SavingsGoalModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0,
      savedAmount: (json['savedAmount'] as num?)?.toDouble() ?? 0,
      deadline: DateTime.tryParse(json['deadline'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}

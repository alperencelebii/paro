// ignore_for_file: prefer_initializing_formals

import 'package:objectbox/objectbox.dart';

/// Represents the period type for a budget
enum BudgetPeriod {
  monthly,
  weekly,
  yearly,
}

/// Helper extensions for BudgetPeriod
extension BudgetPeriodExtension on BudgetPeriod {
  /// Get a user-friendly name for the period
  String get displayName {
    switch (this) {
      case BudgetPeriod.monthly:
        return 'Monthly';
      case BudgetPeriod.weekly:
        return 'Weekly';
      case BudgetPeriod.yearly:
        return 'Yearly';
    }
  }

  /// Get the number of days in this period (approximate)
  int get daysInPeriod {
    switch (this) {
      case BudgetPeriod.monthly:
        return 30; // Approximate
      case BudgetPeriod.weekly:
        return 7;
      case BudgetPeriod.yearly:
        return 365;
    }
  }
}

/// Budget model class
@Entity()
class Budget {
  // ObjectBox ID
  @Id()
  int? id;

  // UUID used as a business ID
  @Index()
  String uuid = '';

  // Title for the budget
  String title = '';

  double amount = 0.0;

  // Store the period type as an integer (enum index)
  int periodIndex = BudgetPeriod.monthly.index;

  // Start and end dates for the budget period
  @Property(type: PropertyType.date)
  DateTime startDate = DateTime.now();

  @Property(type: PropertyType.date)
  DateTime endDate = DateTime.now().add(const Duration(days: 30));

  // Store creation and update timestamps
  @Property(type: PropertyType.date)
  DateTime createdAt = DateTime.now();

  @Property(type: PropertyType.date)
  DateTime updatedAt = DateTime.now();

  // Flag to mark if this is the active budget
  bool isActive = true;

  /// No-args constructor for ObjectBox
  Budget();

  /// Constructor for creating a new budget
  Budget.create({
    required String uuid,
    required double amount,
    required BudgetPeriod period,
    required DateTime startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool isActive = true,
    String title = '',
  }) {
    this.uuid = uuid;
    this.amount = amount;
    periodIndex = period.index;
    this.startDate = startDate;
    this.title = title.isNotEmpty ? title : '${period.displayName} Budget';

    // Calculate end date based on period if not provided
    this.endDate = endDate ?? _calculateEndDate(startDate, period);

    this.createdAt = createdAt ?? DateTime.now();
    this.updatedAt = updatedAt ?? DateTime.now();
    this.isActive = isActive;
  }

  /// Get the period enum from the stored index
  @Transient()
  BudgetPeriod get period => BudgetPeriod.values[periodIndex];

  /// Calculate the end date based on the start date and period
  DateTime _calculateEndDate(DateTime start, BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.monthly:
        // Last day of the month
        final nextMonth = DateTime(start.year, start.month + 1, 1);
        return nextMonth.subtract(const Duration(days: 1));
      case BudgetPeriod.weekly:
        return start.add(const Duration(days: 7));
      case BudgetPeriod.yearly:
        return DateTime(start.year + 1, start.month, start.day)
            .subtract(const Duration(days: 1));
    }
  }

  /// Calculate days remaining in the budget period
  @Transient()
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays + 1;
  }

  /// Calculate daily budget amount
  @Transient()
  double get dailyBudget {
    if (daysRemaining <= 0) return 0;
    return amount / period.daysInPeriod;
  }

  /// Create a copy with updated fields
  Budget copyWith({
    String? uuid,
    double? amount,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? title,
  }) {
    final result = Budget()
      ..id = id
      ..uuid = uuid ?? this.uuid
      ..amount = amount ?? this.amount
      ..periodIndex = period != null ? period.index : periodIndex
      ..startDate = startDate ?? this.startDate
      ..endDate = endDate ?? this.endDate
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? DateTime.now()
      ..isActive = isActive ?? this.isActive
      ..title = title ?? this.title;

    return result;
  }

  /// Serialize to JSON for logging/export or generic persistence
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'title': title,
      'amount': amount,
      'periodIndex': periodIndex,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'id': id,
    };
  }

  /// Deserialize from JSON
  static Budget fromJson(Map<String, dynamic> json) {
    final b = Budget()
      ..uuid = (json['uuid'] as String? ?? '')
      ..title = (json['title'] as String? ?? '')
      ..amount = (json['amount'] as num?)?.toDouble() ?? 0.0
      ..periodIndex = (json['periodIndex'] as num?)?.toInt() ?? 0
      ..startDate = DateTime.parse(json['startDate'] as String)
      ..endDate = DateTime.parse(json['endDate'] as String)
      ..createdAt = DateTime.parse(json['createdAt'] as String)
      ..updatedAt = DateTime.parse(json['updatedAt'] as String)
      ..isActive = json['isActive'] as bool? ?? false
      ..id = (json['id'] as num?)?.toInt();
    return b;
  }
}

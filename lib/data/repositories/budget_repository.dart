import 'package:finance_track/data/models/budget_model.dart';

abstract class BudgetRepository {
  /// Get the active budget
  Budget? getActiveBudget();

  /// Get all budgets
  List<Budget> getAllBudgets();

  /// Create a new budget
  Budget createBudget({
    required double amount,
    required BudgetPeriod period,
    required DateTime startDate,
    DateTime? endDate,
  });

  /// Update an existing budget
  Budget updateBudget(Budget budget);

  /// Delete a budget by ID
  bool deleteBudget(int id);

  /// Set a specific budget as active
  Budget setActiveBudget(int id);
}

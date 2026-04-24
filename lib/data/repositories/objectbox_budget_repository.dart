import 'package:finance_track/data/objectbox.dart';
import 'package:uuid/uuid.dart';
import '../models/budget_model.dart';
import '../../objectbox.g.dart';

/// Repository for managing budget data
class ObjectBoxBudgetRepository {
  // final Box<Budget> _objectBox.budgetBox;
  final ObjectBox _objectBox;

  /// Constructor that takes an ObjectBox store
  ObjectBoxBudgetRepository(this._objectBox);

  /// Get the active budget
  Budget? getActiveBudget() {
    final query = _objectBox.budgetBox.query(Budget_.isActive.equals(true))
      ..order(Budget_.updatedAt, flags: Order.descending);

    final budgets = query.build().find();

    // If multiple active budgets found (shouldn't happen, but just in case),
    // return the most recently updated one
    if (budgets.isEmpty) {
      return null;
    } else if (budgets.length > 1) {
      // If multiple active budgets found, fix the database by deactivating all except the most recent
      for (int i = 1; i < budgets.length; i++) {
        final budget = budgets[i];
        final updated =
            budget.copyWith(isActive: false, updatedAt: DateTime.now());
        _objectBox.budgetBox.put(updated);
      }
    }

    return budgets.first;
  }

  /// Get all budgets
  List<Budget> getAllBudgets() {
    final query = _objectBox.budgetBox.query()
      ..order(Budget_.createdAt, flags: Order.descending);

    final budgets = query.build().find();

    return budgets;
  }

  /// Create a new budget
  Budget createBudget({
    required double amount,
    required int periodIndex,
    required DateTime startDate,
    DateTime? endDate,
    String title = '',
    bool setAsActive = true,
  }) {
    try {
      // Generate a UUID for the new budget
      final uuid = const Uuid().v4();

      // Create the budget object
      final budget = Budget.create(
        uuid: uuid,
        amount: amount,
        period: BudgetPeriod.values[periodIndex],
        startDate: startDate,
        endDate: endDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: setAsActive,
        title: title,
      );

      if (setAsActive) {
        // Deactivate all existing budgets
        final existingBudgets = getAllBudgets();
        for (final budget in existingBudgets) {
          if (budget.isActive) {
            final updated = budget.copyWith(
              isActive: false,
              updatedAt: DateTime.now(),
            );
            _objectBox.budgetBox.put(updated);
          }
        }
      }

      // Calculate end date if not provided
      final calculatedEndDate =
          endDate ?? _calculateEndDate(startDate, budget.period);

      // Update the budget object with the calculated end date
      final updatedBudget = budget.copyWith(
        endDate: calculatedEndDate,
      );

      final id = _objectBox.budgetBox.put(updatedBudget);
      updatedBudget.id = id;

      return updatedBudget;
    } catch (e) {
      throw Exception('Error creating budget: ${e.toString()}');
    }
  }

  /// Helper method to calculate end date based on period
  DateTime _calculateEndDate(DateTime startDate, BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly:
        return DateTime(startDate.year, startDate.month, startDate.day + 7 - 1);
      case BudgetPeriod.monthly:
        // Last day of the month
        final nextMonth = startDate.month < 12
            ? DateTime(startDate.year, startDate.month + 1, 1)
            : DateTime(startDate.year + 1, 1, 1);
        return nextMonth.subtract(const Duration(days: 1));
      case BudgetPeriod.yearly:
        return DateTime(startDate.year + 1, startDate.month, startDate.day)
            .subtract(const Duration(days: 1));
    }
  }

  /// Update an existing budget
  Budget updateBudget(Budget budget) {
    final updatedBudget = budget.copyWith(
      updatedAt: DateTime.now(),
    );

    _objectBox.budgetBox.put(updatedBudget);
    return updatedBudget;
  }

  /// Delete a budget
  bool deleteBudget(int id) {
    try {
      // Check if this is the active budget
      final budget = _objectBox.budgetBox.get(id);
      if (budget == null) {
        return false;
      }

      // If this is the active budget, try to set another budget as active
      if (budget.isActive) {
        final otherBudgets = getAllBudgets().where((b) => b.id != id).toList();
        if (otherBudgets.isNotEmpty) {
          // Set the most recent budget as active
          final newActiveBudget = otherBudgets.first;
          final updated = newActiveBudget.copyWith(
            isActive: true,
            updatedAt: DateTime.now(),
          );
          _objectBox.budgetBox.put(updated);
        }
      }

      // Now delete the budget
      return _objectBox.budgetBox.remove(id);
    } catch (e) {
      return false;
    }
  }

  /// Set a budget as active and deactivate others
  Budget setActiveBudget(int budgetId) {
    try {
      // First, deactivate all budgets
      final allBudgets = getAllBudgets();
      for (final budget in allBudgets) {
        if (budget.isActive) {
          final updated = budget.copyWith(
            isActive: false,
            updatedAt: DateTime.now(),
          );
          _objectBox.budgetBox.put(updated);
        }
      }

      // Then activate the selected budget
      final budget = _objectBox.budgetBox.get(budgetId);
      if (budget == null) {
        throw Exception('Budget not found with ID: $budgetId');
      }

      final updatedBudget = budget.copyWith(
        isActive: true,
        updatedAt: DateTime.now(),
      );

      // Save the updated budget and verify it was saved correctly
      final id = _objectBox.budgetBox.put(updatedBudget);

      // Verify the budget was saved as active
      final savedBudget = _objectBox.budgetBox.get(id);
      if (savedBudget == null || !savedBudget.isActive) {
        throw Exception('Failed to set budget as active');
      }

      return updatedBudget;
    } catch (e) {
      throw Exception('Error setting budget as active: ${e.toString()}');
    }
  }
}

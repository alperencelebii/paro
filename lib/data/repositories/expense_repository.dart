import '../models/expense_model.dart';

/// Interface for the expense repository
abstract class ExpenseRepository {
  /// Get all expenses
  Future<List<Expense>> getExpenses();

  /// Get expense by ID
  Future<Expense?> getExpenseById(String id);

  /// Add a new expense
  Future<void> addExpense(Expense expense);

  /// Update an existing expense
  Future<void> updateExpense(Expense expense);

  /// Delete an expense
  Future<void> deleteExpense(String id);

  /// Get all expenses
  Future<List<Expense>> getAllExpenses();

  /// Get expenses filtered by category
  Future<List<Expense>> getExpensesByCategory(ExpenseCategory category);

  /// Dispose resources when repository is no longer needed
  void dispose();
}

import '../models/income_model.dart';

/// Interface for the income repository
abstract class IncomeRepository {
  /// Get all incomes
  Future<List<Income>> getIncomes();

  /// Get incomes as a stream
  Stream<List<Income>> getIncomesStream();

  /// Get income by ID
  Future<Income?> getIncomeById(String id);

  /// Add a new income
  Future<void> addIncome(Income income);

  /// Update an existing income
  Future<void> updateIncome(Income income);

  /// Delete an income
  Future<void> deleteIncome(String id);

  /// Get incomes filtered by category
  Future<List<Income>> getIncomesByCategory(IncomeCategory category);

  /// Dispose resources
  void dispose();

  /// Get all incomes
  Future<List<Income>> getAllIncomes();
}

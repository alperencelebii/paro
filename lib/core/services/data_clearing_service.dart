import 'dart:developer' as dev;

import '../../data/repositories/composite_expense_repository.dart';
import '../../data/repositories/composite_income_repository.dart';

/// A service for clearing local data when users log out
class DataClearingService {
  static final DataClearingService _instance = DataClearingService._internal();

  /// Singleton instance
  static DataClearingService get instance => _instance;

  bool _isInitialized = false;
  late CompositeExpenseRepository _expenseRepository;
  late CompositeIncomeRepository _incomeRepository;

  /// Private constructor
  DataClearingService._internal();

  /// Initialize the service with repositories
  void initialize({
    required CompositeExpenseRepository expenseRepository,
    required CompositeIncomeRepository incomeRepository,
  }) {
    if (_isInitialized) return;

    _expenseRepository = expenseRepository;
    _incomeRepository = incomeRepository;

    _isInitialized = true;
    dev.log('DataClearingService initialized');
  }

  /// Clear all local transaction data
  /// This should be called when a user logs out
  Future<void> clearAllLocalData() async {
    if (!_isInitialized) {
      dev.log('DataClearingService not initialized. Cannot clear data.');
      return;
    }

    dev.log('Clearing all local user data...');

    try {
      // Clear expenses first
      await _expenseRepository.clearLocalData();

      // Then clear incomes
      await _incomeRepository.clearLocalData();

      dev.log('All local user data cleared successfully');
    } catch (e) {
      dev.log('Error clearing local user data: $e');
      rethrow;
    }
  }
}

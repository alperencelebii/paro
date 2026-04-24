import 'dart:async';
import 'dart:developer' as dev;

import '../../core/services/sync_service.dart';
import '../models/expense_model.dart';
import 'expense_repository.dart';
import 'firebase_expense_repository.dart';
import 'objectbox_expense_repository.dart';

/// A repository that combines ObjectBox and Firebase implementations
/// for storing expense data in both places
class CompositeExpenseRepository implements ExpenseRepository {
  final ObjectBoxExpenseRepository _localRepository;
  final FirebaseExpenseRepository _cloudRepository;
  final SyncService _syncService;

  /// Constructor taking both ObjectBox and Firebase repositories
  CompositeExpenseRepository({
    required ObjectBoxExpenseRepository localRepository,
    required FirebaseExpenseRepository cloudRepository,
  })  : _localRepository = localRepository,
        _cloudRepository = cloudRepository,
        _syncService = SyncService.instance;

  Stream<List<Expense>> getExpensesStream() {
    // Always use local repository for real-time data
    return _localRepository.getExpensesStream();
  }

  @override
  Future<List<Expense>> getExpenses() async {
    // Always use local repository for faster access
    return _localRepository.getExpenses();
  }

  @override
  Future<List<Expense>> getAllExpenses() async {
    return _localRepository.getAllExpenses();
  }

  @override
  Future<Expense> getExpenseById(String id) async {
    // Always try to get from local storage first
    try {
      return await _localRepository.getExpenseById(id);
    } catch (e) {
      // If not found locally and we have connectivity, try cloud
      if (_syncService.isOnline) {
        try {
          final expense = await _cloudRepository.getExpenseById(id);

          // If found in cloud but not locally, save it locally for future
          await _localRepository.addExpense(expense);

          return expense;
        } catch (cloudError) {
          // Re-throw the original error if cloud also fails
          dev.log('Failed to retrieve expense from cloud: $cloudError');
          rethrow;
        }
      } else {
        // If offline, just rethrow the original error
        dev.log('Failed to retrieve expense and device is offline');
        rethrow;
      }
    }
  }

  @override
  Future<void> addExpense(Expense expense) async {
    try {
      // Add to local storage first
      await _localRepository.addExpense(expense);

      // Try to add to cloud storage if online
      if (_syncService.isOnline) {
        try {
          await _cloudRepository.addExpense(expense);
        } catch (e) {
          dev.log('Failed to save expense to cloud: $e');
          // Queue for sync when online
          await _syncService.queueExpenseSync(expense);
        }
      } else {
        // Queue for sync when online
        await _syncService.queueExpenseSync(expense);
      }
    } catch (e) {
      dev.log('Error in addExpense: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    try {
      // Update locally first
      await _localRepository.updateExpense(expense);

      // Try to update in cloud storage if online
      if (_syncService.isOnline) {
        try {
          await _cloudRepository.updateExpense(expense);
        } catch (e) {
          dev.log('Failed to update expense in cloud: $e');
          // Queue for sync when online
          await _syncService.queueExpenseSync(expense);
        }
      } else {
        // Queue for sync when online
        await _syncService.queueExpenseSync(expense);
      }
    } catch (e) {
      dev.log('Error in updateExpense: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      // Get expense before deletion to ensure we have it for cloud deletion

      // Delete locally first
      await _localRepository.deleteExpense(id);

      // Try to delete from cloud if online
      if (_syncService.isOnline) {
        try {
          await _cloudRepository.deleteExpense(id);
        } catch (e) {
          dev.log('Failed to delete expense from cloud: $e');
          // We won't queue deletion operations - they'll be handled in next sync
        }
      }
    } catch (e) {
      dev.log('Error in deleteExpense: $e');
      rethrow;
    }
  }

  @override
  Future<List<Expense>> getExpensesByCategory(ExpenseCategory category) async {
    // Use local repository for category filtering
    return _localRepository.getExpensesByCategory(category);
  }

  Future<List<Expense>> getExpensesByDate(DateTime date) async {
    // Use local repository for date filtering
    return _localRepository.getExpensesByDate(date);
  }

  Future<List<Expense>> getExpensesByDateRange(
      DateTime start, DateTime end) async {
    // Use local repository for date range filtering
    return _localRepository.getExpensesByDateRange(start, end);
  }

  Future<double> getTotalExpenseAmount() async {
    // Use local repository for total calculation
    return _localRepository.getTotalExpenseAmount();
  }

  /// Clears all expense data from local storage only
  /// Used when a user logs out
  Future<void> clearLocalData() async {
    try {
      await _localRepository.clearAllExpenses();
      dev.log('Successfully cleared all local expense data');
    } catch (e) {
      dev.log('Failed to clear local expense data: $e');
      rethrow;
    }
  }

  /// Dispose resources when repository is no longer needed
  @override
  void dispose() {
    // Nothing to dispose in this implementation
  }
}

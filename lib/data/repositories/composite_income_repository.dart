import 'dart:async';
import 'dart:developer' as dev;

import '../../core/services/sync_service.dart';
import '../models/income_model.dart';
import 'firebase_income_repository.dart';
import 'income_repository.dart';
import 'objectbox_income_repository.dart';

/// A repository that combines ObjectBox and Firebase implementations
/// for storing income data in both places
class CompositeIncomeRepository implements IncomeRepository {
  final ObjectBoxIncomeRepository _localRepository;
  final FirebaseIncomeRepository _cloudRepository;
  final SyncService _syncService;

  /// Constructor taking both ObjectBox and Firebase repositories
  CompositeIncomeRepository({
    required ObjectBoxIncomeRepository localRepository,
    required FirebaseIncomeRepository cloudRepository,
  })  : _localRepository = localRepository,
        _cloudRepository = cloudRepository,
        _syncService = SyncService.instance;

  @override
  Stream<List<Income>> getIncomesStream() {
    // Always use local repository for real-time data
    return _localRepository.getIncomesStream();
  }

  @override
  Future<List<Income>> getIncomes() async {
    // Always use local repository for faster access
    return _localRepository.getIncomes();
  }

  @override
  Future<Income> getIncomeById(String id) async {
    // Always try to get from local storage first
    try {
      return await _localRepository.getIncomeById(id);
    } catch (e) {
      // If not found locally and we have connectivity, try cloud
      if (_syncService.isOnline) {
        try {
          final income = await _cloudRepository.getIncomeById(id);

          // If found in cloud but not locally, save it locally for future
          await _localRepository.addIncome(income);

          return income;
        } catch (cloudError) {
          // Re-throw the original error if cloud also fails
          dev.log('Failed to retrieve income from cloud: $cloudError');
          rethrow;
        }
      } else {
        // If offline, just rethrow the original error
        dev.log('Failed to retrieve income and device is offline');
        rethrow;
      }
    }
  }

  @override
  Future<void> addIncome(Income income) async {
    try {
      // Add to local storage first
      await _localRepository.addIncome(income);

      // Try to add to cloud storage if online
      if (_syncService.isOnline) {
        try {
          await _cloudRepository.addIncome(income);
        } catch (e) {
          dev.log('Failed to save income to cloud: $e');
          // Queue for sync when online
          await _syncService.queueIncomeSync(income);
        }
      } else {
        // Queue for sync when online
        await _syncService.queueIncomeSync(income);
      }
    } catch (e) {
      dev.log('Error in addIncome: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateIncome(Income income) async {
    try {
      // Update locally first
      await _localRepository.updateIncome(income);

      // Try to update in cloud storage if online
      if (_syncService.isOnline) {
        try {
          await _cloudRepository.updateIncome(income);
        } catch (e) {
          dev.log('Failed to update income in cloud: $e');
          // Queue for sync when online
          await _syncService.queueIncomeSync(income);
        }
      } else {
        // Queue for sync when online
        await _syncService.queueIncomeSync(income);
      }
    } catch (e) {
      dev.log('Error in updateIncome: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteIncome(String id) async {
    try {
      // Get income before deletion to ensure we have it for cloud deletion

      // Delete locally first
      await _localRepository.deleteIncome(id);

      // Try to delete from cloud if online
      if (_syncService.isOnline) {
        try {
          await _cloudRepository.deleteIncome(id);
        } catch (e) {
          dev.log('Failed to delete income from cloud: $e');
          // We won't queue deletion operations - they'll be handled in next sync
        }
      }
    } catch (e) {
      dev.log('Error in deleteIncome: $e');
      rethrow;
    }
  }

  @override
  Future<List<Income>> getIncomesByCategory(IncomeCategory category) async {
    // Use local repository for category filtering
    return _localRepository.getIncomesByCategory(category);
  }

  @override
  Future<List<Income>> getAllIncomes() async {
    // Always use local repository
    return _localRepository.getAllIncomes();
  }

  /// Clears all income data from local storage only
  /// Used when a user logs out
  Future<void> clearLocalData() async {
    try {
      await _localRepository.clearAllIncomes();
      dev.log('Successfully cleared all local income data');
    } catch (e) {
      dev.log('Failed to clear local income data: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    // Nothing to dispose
  }
}

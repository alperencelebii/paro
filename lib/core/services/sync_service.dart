import 'dart:async';
import 'dart:developer' as dev;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/expense_model.dart';
import '../../data/models/income_model.dart';
import '../../data/repositories/firebase_expense_repository.dart';
import '../../data/repositories/firebase_income_repository.dart';
import '../../data/repositories/composite_expense_repository.dart';
import '../../data/repositories/composite_income_repository.dart';
// Category sync support can be added later

/// Service to handle synchronization between local and cloud storage
class SyncService {
  static final SyncService _instance = SyncService._internal();

  // Set to false to disable debug logs and improve performance
  static const bool enableDebugLogs = false;

  /// Singleton instance
  static SyncService get instance => _instance;

  late CompositeExpenseRepository _expenseRepository;
  late CompositeIncomeRepository _incomeRepository;
  late FirebaseExpenseRepository _cloudExpenseRepository;
  late FirebaseIncomeRepository _cloudIncomeRepository;
  // late CompositeCategoryRepository _categoryRepository;
  // late FirebaseCategoryRepository _cloudCategoryRepository;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  bool _isInitialized = false;
  bool _isSyncing = false;
  bool _isOnline = true;
  DateTime _lastSyncTime = DateTime.now().subtract(const Duration(days: 1));
  // Minimum interval between syncs to prevent rapid repeated syncs
  static const Duration _minSyncInterval = Duration(minutes: 5);

  // Queue for operations that need to be synced when online
  final List<_PendingOperation> _pendingOperations = [];

  /// Flag indicating if the device is online
  bool get isOnline => _isOnline;

  /// Private constructor
  SyncService._internal();

  /// Initialize the sync service with repositories
  void initialize({
    required CompositeExpenseRepository expenseRepository,
    required CompositeIncomeRepository incomeRepository,
    required FirebaseExpenseRepository cloudExpenseRepository,
    required FirebaseIncomeRepository cloudIncomeRepository,
    // CompositeCategoryRepository? categoryRepository,
    // FirebaseCategoryRepository? cloudCategoryRepository,
  }) {
    if (_isInitialized) return;

    _expenseRepository = expenseRepository;
    _incomeRepository = incomeRepository;
    _cloudExpenseRepository = cloudExpenseRepository;
    _cloudIncomeRepository = cloudIncomeRepository;
    // if (categoryRepository != null && cloudCategoryRepository != null) {
    //   _categoryRepository = categoryRepository;
    //   _cloudCategoryRepository = cloudCategoryRepository;
    // }

    // Listen for connectivity changes
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      _handleConnectivityChange(results.first);
    });

    // Load any pending operations from storage
    _loadPendingOperations();

    _isInitialized = true;
    dev.log('SyncService initialized');
  }

  /// Handle connectivity change
  Future<void> _handleConnectivityChange(ConnectivityResult result) async {
    final wasOffline = !_isOnline;
    _isOnline = result != ConnectivityResult.none;

    if (result == ConnectivityResult.none) {
      dev.log('Device is offline. Sync paused.');
      return;
    }

    dev.log('Device connectivity changed to: $result');

    // Skip if we synced recently to prevent multiple syncs
    final now = DateTime.now();
    if (now.difference(_lastSyncTime) < _minSyncInterval) {
      dev.log(
          'Skipping sync as last sync was less than ${_minSyncInterval.inMinutes} minutes ago');
      return;
    }

    // Use a delay to prevent immediate sync attempts when connection is unstable
    if (wasOffline && _isOnline) {
      dev.log(
          'Device came back online. Waiting a moment before processing pending operations...');
      // Wait a bit before syncing to ensure connection is stable
      await Future.delayed(const Duration(seconds: 3));

      // Check if we're still online after the delay
      if (_isOnline) {
        try {
          // Only process pending operations when coming back online, don't do full sync
          dev.log('Processing pending operations...');
          await _processPendingOperations();
          _lastSyncTime = DateTime.now();
        } catch (e) {
          dev.log('Error processing pending operations: $e');
        }
      }
    }

    // We no longer automatically sync all data on connectivity change
    // This prevents excessive uploads/syncs
  }

  /// Load pending operations from shared preferences
  Future<void> _loadPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList('pending_operations') ?? [];

      for (final json in jsonList) {
        try {
          final operation = _PendingOperation.fromJson(json);
          _pendingOperations.add(operation);
        } catch (e) {
          dev.log('Failed to parse pending operation: $e');
        }
      }

      dev.log('Loaded ${_pendingOperations.length} pending operations');
    } catch (e) {
      dev.log('Error loading pending operations: $e');
    }
  }

  /// Save pending operations to shared preferences
  Future<void> _savePendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _pendingOperations.map((op) => op.toJson()).toList();
      await prefs.setStringList('pending_operations', jsonList);
      dev.log('Saved ${_pendingOperations.length} pending operations');
    } catch (e) {
      dev.log('Error saving pending operations: $e');
    }
  }

  /// Add an expense to the sync queue
  Future<void> queueExpenseSync(Expense expense) async {
    _pendingOperations.add(
      _PendingOperation(
        type: _OperationType.expense,
        id: expense.uuid,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    await _savePendingOperations();
  }

  /// Add an income to the sync queue
  Future<void> queueIncomeSync(Income income) async {
    _pendingOperations.add(
      _PendingOperation(
        type: _OperationType.income,
        id: income.uuid,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    await _savePendingOperations();
  }

  /// Process all pending operations
  Future<void> _processPendingOperations() async {
    if (_pendingOperations.isEmpty) return;

    dev.log('Processing ${_pendingOperations.length} pending operations');

    // Sort operations by timestamp (oldest first)
    _pendingOperations.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Cap the number of operations to process in a single batch to avoid overloading
    const int maxOperationsPerBatch = 20;
    final operationsToProcess =
        _pendingOperations.length > maxOperationsPerBatch
            ? _pendingOperations.sublist(0, maxOperationsPerBatch)
            : List<_PendingOperation>.from(_pendingOperations);

    final successfulOperations = <_PendingOperation>[];
    final failedOperations = <_PendingOperation>[];

    for (final operation in operationsToProcess) {
      try {
        if (operation.type == _OperationType.expense) {
          // Find the expense in local repository
          try {
            final expense =
                await _expenseRepository.getExpenseById(operation.id);

            // Ensure we don't have synchronization conflicts by checking if the expense exists in Firebase
            try {
              await _cloudExpenseRepository.getExpenseById(operation.id);
              // If no exception, then it already exists, so update it instead of adding
              await _cloudExpenseRepository.updateExpense(expense);
            } catch (e) {
              // Expense doesn't exist in Firebase, so add it
              await _cloudExpenseRepository.addExpense(expense);
            }

            successfulOperations.add(operation);
            dev.log('Successfully processed pending expense: ${operation.id}');
          } catch (e) {
            dev.log(
                'Failed to process pending expense: ${operation.id}, error: $e');

            // Mark it as failed if we couldn't find it in local storage
            // to prevent repeatedly trying to process it
            failedOperations.add(operation);
          }
        } else if (operation.type == _OperationType.income) {
          // Find the income in local repository
          try {
            final income = await _incomeRepository.getIncomeById(operation.id);

            // Ensure we don't have synchronization conflicts by checking if the income exists in Firebase
            try {
              await _cloudIncomeRepository.getIncomeById(operation.id);
              // If no exception, then it already exists, so update it instead of adding
              await _cloudIncomeRepository.updateIncome(income);
            } catch (e) {
              // Income doesn't exist in Firebase, so add it
              await _cloudIncomeRepository.addIncome(income);
            }

            successfulOperations.add(operation);
            dev.log('Successfully processed pending income: ${operation.id}');
          } catch (e) {
            dev.log(
                'Failed to process pending income: ${operation.id}, error: $e');

            // Mark it as failed if we couldn't find it in local storage
            // to prevent repeatedly trying to process it
            failedOperations.add(operation);
          }
        }
      } catch (e) {
        dev.log('Error processing operation ${operation.id}: $e');
      }
    }

    // Remove all successful operations from the pending list
    for (final operation in successfulOperations) {
      _pendingOperations.remove(operation);
    }

    // If an operation has failed multiple times, remove it to prevent endless retries
    for (final operation in failedOperations) {
      final retryThreshold = DateTime.now().millisecondsSinceEpoch -
          (24 * 60 * 60 * 1000); // 24 hours
      if (operation.timestamp < retryThreshold) {
        _pendingOperations.remove(operation);
        dev.log(
            'Removing operation ${operation.id} after multiple failures over 24 hours');
      }
    }

    // Save the updated pending operations list
    await _savePendingOperations();
  }

  /// Manually trigger data synchronization
  Future<void> syncData() async {
    if (_isSyncing) {
      dev.log('Sync already in progress. Skipping request.');
      return;
    }

    if (!_isInitialized) {
      dev.log('SyncService not initialized. Skipping sync.');
      return;
    }

    // Skip if we synced recently to prevent multiple syncs
    final now = DateTime.now();
    if (now.difference(_lastSyncTime) < _minSyncInterval) {
      dev.log(
          'Skipping sync as last sync was less than ${_minSyncInterval.inMinutes} minutes ago');
      return;
    }

    // If device is offline, don't attempt to sync
    if (!_isOnline) {
      dev.log('Device is offline. Cannot sync data.');
      return;
    }

    try {
      _isSyncing = true;
      dev.log('Starting data synchronization...');

      // Process any pending operations first
      await _processPendingOperations();

      // First sync incomes
      await _syncIncomes();

      // Then sync expenses
      await _syncExpenses();

      _lastSyncTime = DateTime.now();
      dev.log('Data synchronization completed successfully');
    } catch (e) {
      dev.log('Error during data synchronization: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync all local incomes to cloud
  Future<void> _syncIncomes() async {
    if (!_isOnline) {
      dev.log('Device is offline. Cannot sync incomes.');
      return;
    }

    try {
      dev.log('Syncing income data...');
      // Get all local incomes
      final incomes = await _incomeRepository.getAllIncomes();

      // Sync each income to cloud
      int successCount = 0;
      for (final income in incomes) {
        try {
          await _saveIncomeToCloud(income);
          successCount++;
        } catch (e) {
          dev.log('Failed to sync income ${income.uuid}: $e');
          // Queue for later if there's an error
          await queueIncomeSync(income);
        }
      }

      dev.log(
          'Income sync completed. Synced $successCount/${incomes.length} records');
    } catch (e) {
      dev.log('Error during income sync: $e');
    }
  }

  /// Sync all local expenses to cloud
  Future<void> _syncExpenses() async {
    if (!_isOnline) {
      dev.log('Device is offline. Cannot sync expenses.');
      return;
    }

    try {
      dev.log('Syncing expense data...');
      // Get all local expenses
      final expenses = await _expenseRepository.getAllExpenses();

      // Sync each expense to cloud
      int successCount = 0;
      for (final expense in expenses) {
        try {
          await _saveExpenseToCloud(expense);
          successCount++;
        } catch (e) {
          dev.log('Failed to sync expense ${expense.uuid}: $e');
          // Queue for later if there's an error
          await queueExpenseSync(expense);
        }
      }

      dev.log(
          'Expense sync completed. Synced $successCount/${expenses.length} records');
    } catch (e) {
      dev.log('Error during expense sync: $e');
    }
  }

  /// Save income to Firebase
  Future<void> _saveIncomeToCloud(Income income) async {
    if (!_isOnline) {
      if (enableDebugLogs) {
        dev.log(
            'Device is offline. Queuing income for later sync: ${income.uuid}');
      }
      await queueIncomeSync(income);
      return;
    }

    try {
      // Check if income already exists in Firebase
      try {
        await _cloudIncomeRepository.getIncomeById(income.uuid);
        // If we reach here, it exists, so update it
        await _cloudIncomeRepository.updateIncome(income);
      } catch (e) {
        // Income doesn't exist, add it
        await _cloudIncomeRepository.addIncome(income);
      }

      if (enableDebugLogs) {
        dev.log('Successfully saved income to cloud: ${income.uuid}');
      }
    } catch (e) {
      if (enableDebugLogs) {
        dev.log('Failed to save income to cloud: $e');
      }

      // Check if the income is already in the pending operations before queueing again
      // to prevent endless requeueing of the same income
      final isPending = _pendingOperations.any(
          (op) => op.type == _OperationType.income && op.id == income.uuid);

      if (!isPending) {
        // Only queue if not already in the pending operations
        await queueIncomeSync(income);
      } else if (enableDebugLogs) {
        dev.log(
            'Income ${income.uuid} already in pending queue, not queueing again');
      }

      // Don't rethrow the error, as it would cause the sync process to stop
      // This allows the sync to continue with other incomes even if one fails
    }
  }

  /// Save expense to Firebase
  Future<void> _saveExpenseToCloud(Expense expense) async {
    if (!_isOnline) {
      if (enableDebugLogs) {
        dev.log(
            'Device is offline. Queuing expense for later sync: ${expense.uuid}');
      }
      await queueExpenseSync(expense);
      return;
    }

    try {
      // Check if expense already exists in Firebase
      try {
        await _cloudExpenseRepository.getExpenseById(expense.uuid);
        // If we reach here, it exists, so update it
        await _cloudExpenseRepository.updateExpense(expense);
      } catch (e) {
        // Expense doesn't exist, add it
        await _cloudExpenseRepository.addExpense(expense);
      }

      if (enableDebugLogs) {
        dev.log('Successfully saved expense to cloud: ${expense.uuid}');
      }
    } catch (e) {
      if (enableDebugLogs) {
        dev.log('Failed to save expense to cloud: $e');
      }

      // Check if the expense is already in the pending operations before queueing again
      // to prevent endless requeueing of the same expense
      final isPending = _pendingOperations.any(
          (op) => op.type == _OperationType.expense && op.id == expense.uuid);

      if (!isPending) {
        // Only queue if not already in the pending operations
        await queueExpenseSync(expense);
      } else if (enableDebugLogs) {
        dev.log(
            'Expense ${expense.uuid} already in pending queue, not queueing again');
      }

      // Don't rethrow the error, as it would cause the sync process to stop
      // This allows the sync to continue with other expenses even if one fails
    }
  }

  /// Dispose the service and cancel subscriptions
  void dispose() {
    if (_isInitialized) {
      _connectivitySubscription.cancel();
      _isInitialized = false;
      dev.log('SyncService disposed');
    }
  }
}

/// Type of pending operation
enum _OperationType {
  expense,
  income,
}

/// A pending operation to be synced when online
class _PendingOperation {
  final _OperationType type;
  final String id;
  final int timestamp;

  _PendingOperation({
    required this.type,
    required this.id,
    required this.timestamp,
  });

  /// Convert to JSON string
  String toJson() {
    return '${type.index}:$id:$timestamp';
  }

  /// Create from JSON string
  factory _PendingOperation.fromJson(String json) {
    final parts = json.split(':');
    if (parts.length != 3) {
      throw FormatException('Invalid pending operation format: $json');
    }

    return _PendingOperation(
      type: _OperationType.values[int.parse(parts[0])],
      id: parts[1],
      timestamp: int.parse(parts[2]),
    );
  }
}

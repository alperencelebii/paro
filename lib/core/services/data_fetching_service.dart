import 'dart:async';
import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/expense_model.dart';
import '../../data/models/income_model.dart';
import '../../data/models/budget_model.dart';
import '../../data/repositories/firebase_expense_repository.dart';
import '../../data/repositories/firebase_income_repository.dart';
import '../../data/repositories/firebase_budget_repository.dart';
import '../../data/repositories/objectbox_expense_repository.dart';
import '../../data/repositories/objectbox_income_repository.dart';
import '../../data/repositories/objectbox_budget_repository.dart';
import '../../data/objectbox.dart';

/// Base class for data fetch status
abstract class DataFetchStatus {
  const DataFetchStatus();
}

/// Initial status, fetching not started
class DataFetchInitial extends DataFetchStatus {
  const DataFetchInitial();
}

/// Loading status with progress information
class DataFetchLoading extends DataFetchStatus {
  /// Progress from 0.0 to 1.0
  final double progress;

  /// Status message
  final String message;

  /// Constructor
  const DataFetchLoading({
    this.progress = 0.0,
    this.message = 'Loading your data...',
  });
}

/// Success status
class DataFetchSuccess extends DataFetchStatus {
  /// Constructor
  const DataFetchSuccess();
}

/// Error status with error information
class DataFetchError extends DataFetchStatus {
  /// Error message
  final String errorMessage;

  /// Constructor
  const DataFetchError(this.errorMessage);
}

/// Empty status, no data found
class DataFetchEmpty extends DataFetchStatus {
  /// Constructor
  const DataFetchEmpty();
}

/// Service for fetching user data from Firebase to local storage
class DataFetchingService {
  static final DataFetchingService _instance = DataFetchingService._internal();

  /// Singleton instance
  static DataFetchingService get instance => _instance;

  final _statusController = StreamController<DataFetchStatus>.broadcast();

  /// Stream of data fetching status
  Stream<DataFetchStatus> get status => _statusController.stream;

  bool _isInitialized = false;
  bool _isFetching = false;
  DataFetchStatus _currentStatus = const DataFetchInitial();

  late ObjectBoxExpenseRepository _localExpenseRepository;
  late ObjectBoxIncomeRepository _localIncomeRepository;
  late ObjectBoxBudgetRepository _localBudgetRepository;
  late FirebaseExpenseRepository _cloudExpenseRepository;
  late FirebaseIncomeRepository _cloudIncomeRepository;
  late FirebaseBudgetRepository _cloudBudgetRepository;

  int _totalItemsToFetch = 0;
  int _fetchedItems = 0;

  /// Get the current fetch progress from 0.0 to 1.0
  double get fetchProgress {
    if (_totalItemsToFetch == 0) return 0.0;
    return _fetchedItems / _totalItemsToFetch;
  }

  /// Get the current fetch status
  DataFetchStatus get currentStatus => _currentStatus;

  /// Private constructor
  DataFetchingService._internal();

  /// Initialize the service with repositories
  void initialize({
    required ObjectBoxExpenseRepository localExpenseRepository,
    required ObjectBoxIncomeRepository localIncomeRepository,
    required ObjectBoxBudgetRepository localBudgetRepository,
    required FirebaseExpenseRepository cloudExpenseRepository,
    required FirebaseIncomeRepository cloudIncomeRepository,
    required FirebaseBudgetRepository cloudBudgetRepository,
  }) {
    if (_isInitialized) return;

    _localExpenseRepository = localExpenseRepository;
    _localIncomeRepository = localIncomeRepository;
    _localBudgetRepository = localBudgetRepository;
    _cloudExpenseRepository = cloudExpenseRepository;
    _cloudIncomeRepository = cloudIncomeRepository;
    _cloudBudgetRepository = cloudBudgetRepository;

    _isInitialized = true;
    dev.log('DataFetchingService initialized');
  }

  /// Start fetching user data from Firebase to local storage
  /// Returns a stream of the fetch status
  Stream<DataFetchStatus> fetchUserData() {
    if (!_isInitialized) {
      dev.log('DataFetchingService not initialized');
      _updateStatus(const DataFetchError('Service not initialized'));
      return _statusController.stream;
    }

    if (_isFetching) {
      dev.log('Data fetch already in progress');
      return _statusController.stream;
    }

    _startFetching();
    return _statusController.stream;
  }

  /// Start the fetching process
  Future<void> _startFetching() async {
    _isFetching = true;
    _fetchedItems = 0;
    _totalItemsToFetch = 0;

    _updateStatus(const DataFetchLoading(message: 'Starting data fetch...'));

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        dev.log('No authenticated user found');
        _updateStatus(const DataFetchError('No authenticated user found'));
        _isFetching = false;
        return;
      }

      dev.log('Starting to fetch user data for ${user.uid}');

      // Calculate total items to be fetched to track progress
      final estimatedCount = await _estimateTotalItemCount();
      _totalItemsToFetch = estimatedCount;

      _updateStatus(DataFetchLoading(
          progress: 0.1,
          message: 'Found $_totalItemsToFetch items to fetch...'));

      if (_totalItemsToFetch == 0) {
        dev.log('No data to fetch for user');
        _updateStatus(const DataFetchEmpty());
        _isFetching = false;
        return;
      }

      _updateStatus(const DataFetchLoading(
          progress: 0.2, message: 'Fetching income data...'));

      // Fetch and store incomes
      final incomes = await _fetchIncomes();

      _updateStatus(const DataFetchLoading(
          progress: 0.6, message: 'Fetching expense data...'));

      // Fetch and store expenses
      final expenses = await _fetchExpenses();

      _updateStatus(const DataFetchLoading(
          progress: 0.8, message: 'Fetching budget data...'));

      // Fetch and store budgets
      final budgets = await _fetchBudgets();

      // Check if any data was fetched
      if (incomes.isEmpty && expenses.isEmpty && budgets.isEmpty) {
        dev.log('No data fetched for user');
        _updateStatus(const DataFetchEmpty());
      } else {
        dev.log(
            'Successfully fetched user data: ${incomes.length} incomes, ${expenses.length} expenses, ${budgets.length} budgets');
        _updateStatus(const DataFetchSuccess());
      }
    } catch (e) {
      dev.log('Error fetching user data: $e');
      _updateStatus(DataFetchError(e.toString()));
    } finally {
      _isFetching = false;
    }
  }

  /// Estimate the total number of items to be fetched
  Future<int> _estimateTotalItemCount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 0;

      final db = FirebaseFirestore.instance;

      // Get count of incomes
      final incomesQuery = await db
          .collection('users')
          .doc(user.uid)
          .collection('incomes')
          .count()
          .get();

      // Get count of expenses
      final expensesQuery = await db
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .count()
          .get();

      // Get count of budgets
      final budgetsQuery = await db
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .count()
          .get();

      return (incomesQuery.count ?? 0) + 
             (expensesQuery.count ?? 0) + 
             (budgetsQuery.count ?? 0);
    } catch (e) {
      dev.log('Error estimating total item count: $e');
      return 0;
    }
  }

  /// Fetch all income data from Firebase
  Future<List<Income>> _fetchIncomes() async {
    try {
      final incomes = await _cloudIncomeRepository.getAllIncomes();

      if (incomes.isNotEmpty) {
        // Store each income locally
        for (final income in incomes) {
          try {
            // First check if this income already exists locally by querying by UUID
            final existingIncomes =
                await _localIncomeRepository.getAllIncomes();
            final existingIncome =
                existingIncomes.where((e) => e.uuid == income.uuid).firstOrNull;

            if (existingIncome == null) {
              // Only add if it doesn't exist
              await _localIncomeRepository.addIncome(income);
            } else {
              // If it exists, update it to ensure it's in sync
              await _localIncomeRepository.updateIncome(income);
            }
          } catch (e) {
            // If there's an error checking, just add it (may lead to duplication but better than missing data)
            await _localIncomeRepository.addIncome(income);
            dev.log('Error checking for existing income, adding anyway: $e');
          }
          _fetchedItems++;
        }
      }

      return incomes;
    } catch (e) {
      dev.log('Error fetching incomes: $e');
      return [];
    }
  }

  /// Fetch all expense data from Firebase
  Future<List<Expense>> _fetchExpenses() async {
    try {
      final expenses = await _cloudExpenseRepository.getAllExpenses();

      if (expenses.isNotEmpty) {
        // Store each expense locally
        for (final expense in expenses) {
          try {
            // First check if this expense already exists locally by querying by UUID
            final existingExpenses =
                await _localExpenseRepository.getAllExpenses();
            final existingExpense = existingExpenses
                .where((e) => e.uuid == expense.uuid)
                .firstOrNull;

            if (existingExpense == null) {
              // Only add if it doesn't exist
              await _localExpenseRepository.addExpense(expense);
            } else {
              // If it exists, update it to ensure it's in sync
              await _localExpenseRepository.updateExpense(expense);
            }
          } catch (e) {
            // If there's an error checking, just add it (may lead to duplication but better than missing data)
            await _localExpenseRepository.addExpense(expense);
            dev.log('Error checking for existing expense, adding anyway: $e');
          }
          _fetchedItems++;
        }
      }

      return expenses;
    } catch (e) {
      dev.log('Error fetching expenses: $e');
      return [];
    }
  }

  /// Fetch all budget data from Firebase
  Future<List<Budget>> _fetchBudgets() async {
    try {
      final budgets = await _cloudBudgetRepository.getAll();

      if (budgets.isNotEmpty) {
        // Store each budget locally
        for (final budget in budgets) {
          try {
            // First check if this budget already exists locally by querying by UUID
            final existingBudgets = _localBudgetRepository.getAllBudgets();
            final existingBudget = existingBudgets
                .where((b) => b.uuid == budget.uuid)
                .firstOrNull;

            if (existingBudget == null) {
              // Budget doesn't exist locally, create it with the original UUID
              // Create a new budget object with all the original data
              final newBudget = Budget()
                ..uuid = budget.uuid
                ..title = budget.title
                ..amount = budget.amount
                ..periodIndex = budget.periodIndex
                ..startDate = budget.startDate
                ..endDate = budget.endDate
                ..createdAt = budget.createdAt
                ..updatedAt = budget.updatedAt
                ..isActive = budget.isActive;
              
              // Save directly to ObjectBox to preserve UUID
              ObjectBox.instance.budgetBox.put(newBudget);
            } else {
              // If it exists, update it to ensure it's in sync
              final updatedBudget = existingBudget.copyWith(
                title: budget.title,
                amount: budget.amount,
                period: BudgetPeriod.values[budget.periodIndex],
                startDate: budget.startDate,
                endDate: budget.endDate,
                isActive: budget.isActive,
                updatedAt: budget.updatedAt,
              );
              _localBudgetRepository.updateBudget(updatedBudget);
            }
          } catch (e) {
            dev.log('Error syncing budget ${budget.uuid}: $e');
            // Try to create it anyway
            try {
              _localBudgetRepository.createBudget(
                amount: budget.amount,
                periodIndex: budget.periodIndex,
                startDate: budget.startDate,
                endDate: budget.endDate,
                title: budget.title,
                setAsActive: budget.isActive,
              );
            } catch (createError) {
              dev.log('Error creating budget: $createError');
            }
          }
          _fetchedItems++;
        }
      }

      return budgets;
    } catch (e) {
      dev.log('Error fetching budgets: $e');
      return [];
    }
  }

  /// Update the status and emit to the stream
  void _updateStatus(DataFetchStatus status) {
    _currentStatus = status;
    _statusController.add(status);

    // If status is loading with progress, also update progress
    if (status is DataFetchLoading) {
      // Update progress if specific progress wasn't provided
      if (status.progress == 0 && _totalItemsToFetch > 0) {
        final progress = fetchProgress;
        _statusController.add(DataFetchLoading(
          progress: progress,
          message: status.message,
        ));
      }
    }
  }

  /// Reset the service state
  void reset() {
    _isFetching = false;
    _fetchedItems = 0;
    _totalItemsToFetch = 0;
    _updateStatus(const DataFetchInitial());
  }

  /// Dispose the service
  void dispose() {
    _statusController.close();
  }
}

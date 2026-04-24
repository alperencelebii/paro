import 'package:finance_track/core/services/data_clearing_service.dart';
import 'package:finance_track/core/services/data_fetching_service.dart';
import 'package:finance_track/core/services/sync_service.dart';
import 'package:finance_track/data/repositories/objectbox_budget_repository.dart';
import 'package:finance_track/data/repositories/composite_budget_repository.dart';
import 'package:finance_track/data/repositories/firebase_budget_repository.dart';
import 'package:flutter/material.dart';
import '../data/objectbox.dart';
import '../data/repositories/composite_expense_repository.dart';
import '../data/repositories/composite_income_repository.dart';
import '../data/repositories/expense_repository.dart';
import '../data/repositories/firebase_expense_repository.dart';
import '../data/repositories/firebase_income_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/objectbox_category_repository.dart';
import '../data/repositories/firebase_category_repository.dart';
import '../data/repositories/composite_category_repository.dart';
import '../data/repositories/income_repository.dart';
import '../data/repositories/mock_expense_repository.dart';
import '../data/repositories/mock_income_repository.dart';
import '../data/repositories/objectbox_expense_repository.dart';
import '../data/repositories/objectbox_income_repository.dart';
import 'router/navigation_manager.dart';

/// Result class for repository initialization
class RepositoryInitResult {
  final ExpenseRepository expenseRepository;
  final IncomeRepository incomeRepository;
  final CompositeBudgetRepository budgetRepository;
  final CategoryRepository? categoryRepository;
  final bool hasError;
  final String errorMessage;

  const RepositoryInitResult({
    required this.expenseRepository,
    required this.incomeRepository,
    required this.budgetRepository,
    this.categoryRepository,
    this.hasError = false,
    this.errorMessage = '',
  });
}

/// Initialize the repository and handle errors
Future<RepositoryInitResult> initializeRepositories() async {
  try {
    // Get the ObjectBox instance that was already initialized
    final objectBox = ObjectBox.instance;

    // Initialize ObjectBox repositories
    final objectBoxExpenseRepository = ObjectBoxExpenseRepository(objectBox);
    final objectBoxIncomeRepository = ObjectBoxIncomeRepository(objectBox);
    final localBudgetRepository = ObjectBoxBudgetRepository(objectBox);

    // Initialize Firebase repositories
    final firebaseExpenseRepository = FirebaseExpenseRepository();
    final firebaseIncomeRepository = FirebaseIncomeRepository();
    final firebaseCategoryRepository = FirebaseCategoryRepository();
    final firebaseBudgetRepository = FirebaseBudgetRepository();

    // Create composite repositories that use both storage methods
    final expenseRepository = CompositeExpenseRepository(
      localRepository: objectBoxExpenseRepository,
      cloudRepository: firebaseExpenseRepository,
    );

    final incomeRepository = CompositeIncomeRepository(
      localRepository: objectBoxIncomeRepository,
      cloudRepository: firebaseIncomeRepository,
    );

    // Categories repository (Composite: ObjectBox + Firebase)
    final objectBoxCategoryRepository = ObjectBoxCategoryRepository(objectBox);
    final categoryRepository = CompositeCategoryRepository(
      local: objectBoxCategoryRepository,
      cloud: firebaseCategoryRepository,
    );

    // Budget repository (Composite)
    final budgetRepository = CompositeBudgetRepository(
      local: localBudgetRepository,
      cloud: firebaseBudgetRepository,
    );

    // Initialize sync service
    SyncService.instance.initialize(
      expenseRepository: expenseRepository,
      incomeRepository: incomeRepository,
      cloudExpenseRepository: firebaseExpenseRepository,
      cloudIncomeRepository: firebaseIncomeRepository,
    );

    // Initialize data clearing service
    DataClearingService.instance.initialize(
      expenseRepository: expenseRepository,
      incomeRepository: incomeRepository,
    );

    // Initialize data fetching service
    DataFetchingService.instance.initialize(
      localExpenseRepository: objectBoxExpenseRepository,
      localIncomeRepository: objectBoxIncomeRepository,
      localBudgetRepository: localBudgetRepository,
      cloudExpenseRepository: firebaseExpenseRepository,
      cloudIncomeRepository: firebaseIncomeRepository,
      cloudBudgetRepository: firebaseBudgetRepository,
    );

    debugPrint('Using Composite (ObjectBox + Firebase) repository for storage');

    return RepositoryInitResult(
      expenseRepository: expenseRepository,
      incomeRepository: incomeRepository,
      categoryRepository: categoryRepository,
      budgetRepository: budgetRepository,
    );
  } catch (e) {
    // If initialization fails, use the mock repository as temporary fallback
    debugPrint('Repository initialization failed: $e');
    debugPrint('Using temporary Mock repository as fallback');

    final objectBox =
        ObjectBox.isInitialized ? ObjectBox.instance : await ObjectBox.create();

    return RepositoryInitResult(
      budgetRepository: CompositeBudgetRepository(
        local: ObjectBoxBudgetRepository(objectBox),
        cloud: FirebaseBudgetRepository(),
      ),
      expenseRepository: MockExpenseRepository(),
      incomeRepository: MockIncomeRepository(),
      categoryRepository: null,
      hasError: true,
      errorMessage: e.toString(),
    );
  }
}

/// Show error dialog if database failed to initialize
void showDatabaseErrorDialog(String errorMessage) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    NavigationManager.navigatorKey.currentState?.overlay?.context
        .let((context) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Database Initialization Failed'),
          content: SingleChildScrollView(
            child: Text(
              'The app database could not be initialized. '
              'You are using a temporary in-memory database. '
              'Your data will not be saved when you close the app.\n\n'
              'Error details:\n$errorMessage',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  });
}

/// Extension for working with nullable context
extension BuildContextExt on BuildContext? {
  void let(Function(BuildContext context) block) {
    final context = this;
    if (context != null) {
      block(context);
    }
  }
}

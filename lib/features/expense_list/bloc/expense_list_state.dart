import 'package:equatable/equatable.dart';
import '../../../data/models/expense_model.dart';

/// States for the ExpenseListBloc
abstract class ExpenseListState extends Equatable {
  const ExpenseListState();

  @override
  List<Object?> get props => [];
}

/// Loading state
class ExpenseListLoading extends ExpenseListState {
  const ExpenseListLoading();
}

/// Error state when loading expenses
class ExpenseListError extends ExpenseListState {
  final String message;

  const ExpenseListError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Loaded state with expenses
class ExpenseListLoaded extends ExpenseListState {
  final List<Expense> expenses;
  final ExpenseCategory? filterCategory;

  // For future implementation of multi-category filtering
  final Set<ExpenseCategory>? filterCategories;

  const ExpenseListLoaded({
    required this.expenses,
    this.filterCategory,
    this.filterCategories,
  });

  /// Get filtered expenses based on the category filter
  List<Expense> get filteredExpenses {
    // If filterCategories is implemented and has values, use it
    if (filterCategories != null && filterCategories!.isNotEmpty) {
      return expenses
          .where((expense) => filterCategories!.contains(expense.category))
          .toList();
    }

    // Otherwise use the single category filter
    if (filterCategory == null) {
      return expenses;
    }
    return expenses
        .where((expense) => expense.category == filterCategory)
        .toList();
  }

  /// Get total expenses amount
  double get totalAmount {
    return filteredExpenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  @override
  List<Object?> get props => [expenses, filterCategory, filterCategories];

  /// Create a copy with updated parameters
  ExpenseListLoaded copyWith({
    List<Expense>? expenses,
    ExpenseCategory? filterCategory,
    Set<ExpenseCategory>? filterCategories,
    bool clearFilter = false,
  }) {
    return ExpenseListLoaded(
      expenses: expenses ?? this.expenses,
      filterCategory:
          clearFilter ? null : (filterCategory ?? this.filterCategory),
      filterCategories:
          clearFilter ? null : (filterCategories ?? this.filterCategories),
    );
  }
}

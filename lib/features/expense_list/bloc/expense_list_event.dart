import 'package:equatable/equatable.dart';
import '../../../data/models/expense_model.dart';

/// Events for the ExpenseListBloc
abstract class ExpenseListEvent extends Equatable {
  const ExpenseListEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all expenses
class LoadExpenses extends ExpenseListEvent {
  const LoadExpenses();
}

/// Event to add a new expense
class AddExpense extends ExpenseListEvent {
  final Expense expense;

  const AddExpense(this.expense);

  @override
  List<Object> get props => [expense];
}

/// Event to delete an expense
class DeleteExpense extends ExpenseListEvent {
  final String expenseId;

  const DeleteExpense(this.expenseId);

  @override
  List<Object> get props => [expenseId];
}

/// Event to update an expense
class UpdateExpense extends ExpenseListEvent {
  final Expense expense;

  const UpdateExpense(this.expense);

  @override
  List<Object> get props => [expense];
}

/// Event to filter expenses by a single category
class FilterExpensesByCategory extends ExpenseListEvent {
  final ExpenseCategory? category;

  const FilterExpensesByCategory(this.category);

  @override
  List<Object?> get props => [category];
}

/// Event to filter expenses by multiple categories
class FilterExpensesByCategories extends ExpenseListEvent {
  final Set<ExpenseCategory> categories;

  const FilterExpensesByCategories(this.categories);

  @override
  List<Object> get props => [categories];
}

/// Event to clear all filters
class ClearFilters extends ExpenseListEvent {
  const ClearFilters();
}

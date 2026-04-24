import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/expense_repository.dart';
import 'expense_list_event.dart';
import 'expense_list_state.dart';

/// BLoC for managing the expense list
class ExpenseListBloc extends Bloc<ExpenseListEvent, ExpenseListState> {
  final ExpenseRepository _expenseRepository;

  ExpenseListBloc(this._expenseRepository) : super(const ExpenseListLoading()) {
    on<LoadExpenses>(_onLoadExpenses);
    on<AddExpense>(_onAddExpense);
    on<DeleteExpense>(_onDeleteExpense);
    on<FilterExpensesByCategory>(_onFilterExpensesByCategory);
    on<FilterExpensesByCategories>(_onFilterExpensesByCategories);
    on<ClearFilters>(_onClearFilters);
    on<UpdateExpense>(_onUpdateExpense);
  }

  /// Load all expenses handler
  Future<void> _onLoadExpenses(
    LoadExpenses event,
    Emitter<ExpenseListState> emit,
  ) async {
    emit(const ExpenseListLoading());
    try {
      final expenses = await _expenseRepository.getExpenses();
      emit(ExpenseListLoaded(expenses: expenses));
    } catch (e) {
      emit(ExpenseListError(e.toString()));
    }
  }

  /// Add expense handler
  Future<void> _onAddExpense(
    AddExpense event,
    Emitter<ExpenseListState> emit,
  ) async {
    if (state is ExpenseListLoaded) {
      final currentState = state as ExpenseListLoaded;
      emit(const ExpenseListLoading());

      try {
        await _expenseRepository.addExpense(event.expense);
        final updatedExpenses = await _expenseRepository.getExpenses();
        emit(currentState.copyWith(expenses: updatedExpenses));
      } catch (e) {
        emit(ExpenseListError(e.toString()));
      }
    }
  }

  /// Delete expense handler
  Future<void> _onDeleteExpense(
    DeleteExpense event,
    Emitter<ExpenseListState> emit,
  ) async {
    if (state is ExpenseListLoaded) {
      final currentState = state as ExpenseListLoaded;
      emit(const ExpenseListLoading());

      try {
        await _expenseRepository.deleteExpense(event.expenseId);
        final updatedExpenses = await _expenseRepository.getExpenses();
        emit(currentState.copyWith(expenses: updatedExpenses));
      } catch (e) {
        emit(ExpenseListError(e.toString()));
      }
    }
  }

  /// Update expense handler
  Future<void> _onUpdateExpense(
    UpdateExpense event,
    Emitter<ExpenseListState> emit,
  ) async {
    if (state is ExpenseListLoaded) {
      final currentState = state as ExpenseListLoaded;
      emit(const ExpenseListLoading());

      try {
        await _expenseRepository.updateExpense(event.expense);
        final updatedExpenses = await _expenseRepository.getExpenses();
        emit(currentState.copyWith(expenses: updatedExpenses));
      } catch (e) {
        emit(ExpenseListError(e.toString()));
      }
    }
  }

  /// Filter expenses by single category handler
  void _onFilterExpensesByCategory(
    FilterExpensesByCategory event,
    Emitter<ExpenseListState> emit,
  ) {
    if (state is ExpenseListLoaded) {
      final currentState = state as ExpenseListLoaded;
      emit(currentState.copyWith(
        filterCategory: event.category,
        filterCategories:
            null, // Clear multi-category filter when using single filter
      ));
    }
  }

  /// Filter expenses by multiple categories handler
  void _onFilterExpensesByCategories(
    FilterExpensesByCategories event,
    Emitter<ExpenseListState> emit,
  ) {
    if (state is ExpenseListLoaded) {
      final currentState = state as ExpenseListLoaded;
      emit(currentState.copyWith(
        filterCategories: event.categories,
        filterCategory:
            null, // Clear single category filter when using multi-filter
      ));
    }
  }

  /// Clear all filters handler
  void _onClearFilters(
    ClearFilters event,
    Emitter<ExpenseListState> emit,
  ) {
    if (state is ExpenseListLoaded) {
      final currentState = state as ExpenseListLoaded;
      emit(currentState.copyWith(clearFilter: true));
    }
  }
}

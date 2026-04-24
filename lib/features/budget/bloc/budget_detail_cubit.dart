import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../data/models/budget_model.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/income_model.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../data/repositories/income_repository.dart';

class BudgetDetailState extends Equatable {
  final Budget budget;
  final DateTimeRange dateRange;
  final List<Expense> expenses;
  final List<Income> incomes;
  final double totalExpense;
  final double totalIncome;
  final bool isLoading;
  final String? error;
  final Grouping grouping;

  const BudgetDetailState({
    required this.budget,
    required this.dateRange,
    this.expenses = const [],
    this.incomes = const [],
    this.totalExpense = 0,
    this.totalIncome = 0,
    this.isLoading = false,
    this.error,
    this.grouping = Grouping.date,
  });

  BudgetDetailState copyWith({
    Budget? budget,
    DateTimeRange? dateRange,
    List<Expense>? expenses,
    List<Income>? incomes,
    double? totalExpense,
    double? totalIncome,
    bool? isLoading,
    String? error,
    Grouping? grouping,
  }) {
    return BudgetDetailState(
      budget: budget ?? this.budget,
      dateRange: dateRange ?? this.dateRange,
      expenses: expenses ?? this.expenses,
      incomes: incomes ?? this.incomes,
      totalExpense: totalExpense ?? this.totalExpense,
      totalIncome: totalIncome ?? this.totalIncome,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      grouping: grouping ?? this.grouping,
    );
  }

  @override
  List<Object?> get props => [
        budget,
        dateRange,
        expenses,
        incomes,
        totalExpense,
        totalIncome,
        isLoading,
        error,
        grouping,
      ];
}

class BudgetDetailCubit extends Cubit<BudgetDetailState> {
  final ExpenseRepository expenseRepository;
  final IncomeRepository incomeRepository;

  BudgetDetailCubit({
    required Budget budget,
    required DateTimeRange dateRange,
    required this.expenseRepository,
    required this.incomeRepository,
  }) : super(BudgetDetailState(budget: budget, dateRange: dateRange));

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final allExpenses = await expenseRepository.getAllExpenses();
      final allIncomes = await incomeRepository.getAllIncomes();

      final start = DateTime(state.dateRange.start.year,
          state.dateRange.start.month, state.dateRange.start.day);
      final end = DateTime(state.dateRange.end.year, state.dateRange.end.month,
          state.dateRange.end.day, 23, 59, 59, 999);

      bool inRange(DateTime d) => !d.isBefore(start) && !d.isAfter(end);

      final expenses = allExpenses.where((e) => inRange(e.date)).toList();
      final incomes = allIncomes.where((i) => inRange(i.date)).toList();

      final totalExpense = expenses.fold<double>(0, (s, e) => s + e.amount);
      final totalIncome = incomes.fold<double>(0, (s, i) => s + i.amount);

      emit(state.copyWith(
        expenses: expenses,
        incomes: incomes,
        totalExpense: totalExpense,
        totalIncome: totalIncome,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void updateRange(DateTimeRange range) {
    emit(state.copyWith(dateRange: range));
    load();
  }

  void updateGrouping(Grouping grouping) {
    emit(state.copyWith(grouping: grouping));
  }
}

enum Grouping { date, weekly, monthly }

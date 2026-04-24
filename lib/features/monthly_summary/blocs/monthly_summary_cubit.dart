// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:finance_track/core/extensions/currency_context_extension.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import '../../../core/models/currency_model.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/income_model.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../data/repositories/income_repository.dart';
import '../../../data/objectbox.dart';
import '../../../objectbox.g.dart';

// States
abstract class MonthlySummaryState extends Equatable {
  const MonthlySummaryState();

  @override
  List<Object?> get props => [];
}

class MonthlySummaryInitial extends MonthlySummaryState {}

class MonthlySummaryLoading extends MonthlySummaryState {}

class MonthlySummaryError extends MonthlySummaryState {
  final String message;

  const MonthlySummaryError(this.message);

  @override
  List<Object?> get props => [message];
}

class MonthlySummaryLoaded extends MonthlySummaryState {
  final double income;
  final double expense;
  final double balance;
  final Currency currency;
  final double expenseToIncomeRatio;
  final String month;
  final String year;
  final Map<String, double>? categoryBreakdown;
  final Map<int, double>? dailyExpenses;
  final double? previousMonthBalance;
  final Map<String, double>? previousMonthCategories;
  final double? previousMonthTotal;
  final double? previousMonthIncome;
  final double? previousMonthExpense;
  final List<Expense> expenses;
  final List<Income> incomes;
  final Map<String, double> expenseCategories;
  final Map<String, double> incomeCategories;
  final DateTimeRange? dateRange;
  final String periodTitle;
  final Map<DateTime, double> dailyExpensesMap;
  final Map<DateTime, double> dailyIncomesMap;

  const MonthlySummaryLoaded({
    required this.income,
    required this.expense,
    required this.balance,
    required this.currency,
    required this.expenseToIncomeRatio,
    required this.month,
    required this.year,
    this.categoryBreakdown,
    this.dailyExpenses,
    this.previousMonthBalance,
    this.previousMonthCategories,
    this.previousMonthTotal,
    this.previousMonthIncome,
    this.previousMonthExpense,
    required this.expenses,
    required this.incomes,
    required this.expenseCategories,
    required this.incomeCategories,
    this.dateRange,
    required this.periodTitle,
    required this.dailyExpensesMap,
    required this.dailyIncomesMap,
  });

  @override
  List<Object?> get props => [
        income,
        expense,
        balance,
        currency,
        expenseToIncomeRatio,
        month,
        year,
        categoryBreakdown,
        dailyExpenses,
        previousMonthBalance,
        previousMonthCategories,
        previousMonthTotal,
        previousMonthIncome,
        previousMonthExpense,
        expenses,
        incomes,
        expenseCategories,
        incomeCategories,
        dateRange,
        periodTitle,
        dailyExpensesMap,
        dailyIncomesMap,
      ];
}

class MonthlySummaryCubit extends Cubit<MonthlySummaryState> {
  final ExpenseRepository expenseRepository;
  final IncomeRepository incomeRepository;
  final ObjectBox _objectBox;
  StreamSubscription? _expensesSubscription;
  StreamSubscription? _incomesSubscription;

  DateTime _selectedMonth = DateTime.now();
  DateTimeRange? _dateRange;

  MonthlySummaryCubit({
    required this.expenseRepository,
    required this.incomeRepository,
  })  : _objectBox = ObjectBox.instance,
        super(MonthlySummaryInitial());

  Future<void> loadMonthlySummary(BuildContext context) async {
    try {
      emit(MonthlySummaryLoading());

      DateTime startDate;
      DateTime endDate;
      String periodTitle;

      // Determine date range based on selected mode
      if (_dateRange != null) {
        // Custom date range mode
        startDate = _dateRange!.start;
        endDate = DateTime(_dateRange!.end.year, _dateRange!.end.month,
            _dateRange!.end.day, 23, 59, 59);

        // Format period title for date range
        if (startDate.year == endDate.year &&
            startDate.month == endDate.month) {
          // Same month and year
          if (startDate.day == endDate.day) {
            // Same day
            periodTitle = DateFormat('d MMM yyyy').format(startDate);
          } else {
            // Different days, same month
            periodTitle =
                '${DateFormat('d').format(startDate)} - ${DateFormat('d MMM yyyy').format(endDate)}';
          }
        } else if (startDate.year == endDate.year) {
          // Same year, different months
          periodTitle =
              '${DateFormat('d MMM').format(startDate)} - ${DateFormat('d MMM yyyy').format(endDate)}';
        } else {
          // Different years
          periodTitle =
              '${DateFormat('d MMM yyyy').format(startDate)} - ${DateFormat('d MMM yyyy').format(endDate)}';
        }
      } else {
        // Monthly mode (default)
        startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
        endDate = DateTime(
            _selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
        periodTitle = DateFormat('MMMM yyyy').format(_selectedMonth);
      }

      // Cancel existing subscriptions
      await _expensesSubscription?.cancel();
      await _incomesSubscription?.cancel();

      // Create a completer to handle stream completion
      final completer = Completer<void>();
      List<Expense>? filteredExpenses;
      List<Income>? filteredIncomes;

      // Query expenses for the selected date range
      final expenseQueryBuilder = _objectBox.expenseBox.query(Expense_.date
          .between(
              startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch))
        ..order(Expense_.date, flags: Order.descending);

      final expenseQuery = expenseQueryBuilder.build();
      filteredExpenses = expenseQuery.find();
      expenseQuery.close();

      // Query incomes for the selected date range
      final incomeQueryBuilder = _objectBox.incomeBox.query(Income_.date
          .between(
              startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch))
        ..order(Income_.date, flags: Order.descending);

      final incomeQuery = incomeQueryBuilder.build();
      filteredIncomes = incomeQuery.find();
      incomeQuery.close();

      // Update state with the results
      _updateState(
        expenses: filteredExpenses,
        incomes: filteredIncomes,
        startDate: startDate,
        endDate: endDate,
        periodTitle: periodTitle,
        context: context,
      );

      // Set up streams for real-time updates using repository methods
      _expensesSubscription =
          expenseRepository.getAllExpenses().asStream().listen(
        (expenses) {
          final filteredExpenses = expenses.where((expense) {
            return expense.date
                    .isAfter(startDate.subtract(const Duration(minutes: 1))) &&
                expense.date.isBefore(endDate.add(const Duration(minutes: 1)));
          }).toList();
          _updateState(
            expenses: filteredExpenses,
            incomes: filteredIncomes ?? [],
            startDate: startDate,
            endDate: endDate,
            periodTitle: periodTitle,
            context: context,
          );
        },
      );

      _incomesSubscription = incomeRepository.getAllIncomes().asStream().listen(
        (incomes) {
          final filteredIncomes = incomes.where((income) {
            return income.date
                    .isAfter(startDate.subtract(const Duration(minutes: 1))) &&
                income.date.isBefore(endDate.add(const Duration(minutes: 1)));
          }).toList();
          _updateState(
            expenses: filteredExpenses ?? [],
            incomes: filteredIncomes,
            startDate: startDate,
            endDate: endDate,
            periodTitle: periodTitle,
            context: context,
          );
        },
      );

      completer.complete();
      await completer.future;
    } catch (e) {
      emit(MonthlySummaryError(e.toString()));
    }
  }

  void _updateState({
    required List<Expense> expenses,
    required List<Income> incomes,
    required DateTime startDate,
    required DateTime endDate,
    required String periodTitle,
    required BuildContext context,
  }) {
    try {
      // Calculate totals
      final totalIncome =
          incomes.fold<double>(0, (sum, income) => sum + (income.amount));

      final totalExpense =
          expenses.fold<double>(0, (sum, expense) => sum + (expense.amount));

      // Calculate balance
      final balance = totalIncome - totalExpense;

      // Calculate expense to income ratio
      final expenseToIncomeRatio =
          totalIncome > 0 ? (totalExpense / totalIncome) * 100 : 0.0;

      // Process category breakdown
      final Map<String, double> categoryBreakdown = {};
      for (final expense in expenses) {
        final categoryName = expense.category.displayName;
        categoryBreakdown.update(
          categoryName,
          (value) => value + expense.amount,
          ifAbsent: () => expense.amount,
        );
      }

      // Process daily expenses
      final Map<int, double> dailyExpenses = {};
      final Map<DateTime, double> dailyExpensesMap = {};

      for (final expense in expenses) {
        final day = expense.date.day;
        dailyExpenses.update(
          day,
          (value) => value + expense.amount,
          ifAbsent: () => expense.amount,
        );

        // Date with zero time components for consistent lookup
        final dateKey = DateTime(
          expense.date.year,
          expense.date.month,
          expense.date.day,
        );

        dailyExpensesMap.update(
          dateKey,
          (value) => value + expense.amount,
          ifAbsent: () => expense.amount,
        );
      }

      // Process daily incomes
      final Map<DateTime, double> dailyIncomesMap = {};

      for (final income in incomes) {
        // Date with zero time components for consistent lookup
        final dateKey = DateTime(
          income.date.year,
          income.date.month,
          income.date.day,
        );

        dailyIncomesMap.update(
          dateKey,
          (value) => value + income.amount,
          ifAbsent: () => income.amount,
        );
      }

      // Get currency from CurrencyBloc
      final currency = context.selectedCurrency;

      // Format month and year (used for compatibility with previous UI)
      final monthName = DateFormat('MMMM').format(startDate);
      final yearStr = startDate.year.toString();

      // Calculate previous month's data if in month mode
      double? previousMonthBalance;
      Map<String, double>? previousMonthCategories;
      double? previousMonthTotal;
      double? previousMonthIncome;
      double? previousMonthExpense;

      if (_dateRange == null) {
        // Only calculate previous period data in month mode
        final previousMonth =
            DateTime(_selectedMonth.year, _selectedMonth.month - 1);
        final firstDayOfPreviousMonth =
            DateTime(previousMonth.year, previousMonth.month, 1);
        final lastDayOfPreviousMonth = DateTime(
            previousMonth.year, previousMonth.month + 1, 0, 23, 59, 59);

        // Query previous month's expenses
        final previousMonthExpenseQuery = _objectBox.expenseBox
            .query(Expense_.date.between(
                firstDayOfPreviousMonth.millisecondsSinceEpoch,
                lastDayOfPreviousMonth.millisecondsSinceEpoch))
            .build();
        final previousMonthExpenses = previousMonthExpenseQuery.find();
        previousMonthExpenseQuery.close();

        // Query previous month's incomes
        final previousMonthIncomeQuery = _objectBox.incomeBox
            .query(Income_.date.between(
                firstDayOfPreviousMonth.millisecondsSinceEpoch,
                lastDayOfPreviousMonth.millisecondsSinceEpoch))
            .build();
        final previousMonthIncomes = previousMonthIncomeQuery.find();
        previousMonthIncomeQuery.close();

        // Calculate previous month's totals
        previousMonthTotal = previousMonthExpenses.fold<double>(
            0, (sum, expense) => sum + expense.amount);
        previousMonthIncome = previousMonthIncomes.fold<double>(
            0, (sum, income) => sum + income.amount);
        previousMonthExpense = previousMonthExpenses.fold<double>(
            0, (sum, expense) => sum + expense.amount);
        previousMonthBalance = previousMonthIncome - previousMonthExpense;

        // Calculate previous month's categories
        previousMonthCategories = {};
        for (var expense in previousMonthExpenses) {
          previousMonthCategories.update(
            expense.category.name,
            (value) => value + expense.amount,
            ifAbsent: () => expense.amount,
          );
        }
      }

      // Calculate expense categories
      Map<String, double> expenseCategories = {};
      for (var expense in expenses) {
        expenseCategories.update(
          expense.category.name,
          (value) => value + expense.amount,
          ifAbsent: () => expense.amount,
        );
      }

      // Calculate income categories
      Map<String, double> incomeCategories = {};
      for (var income in incomes) {
        incomeCategories.update(
          income.category.name,
          (value) => value + income.amount,
          ifAbsent: () => income.amount,
        );
      }

      emit(MonthlySummaryLoaded(
        income: totalIncome,
        expense: totalExpense,
        balance: balance,
        currency: currency,
        expenseToIncomeRatio: expenseToIncomeRatio,
        month: monthName,
        year: yearStr,
        categoryBreakdown: categoryBreakdown,
        dailyExpenses: dailyExpenses,
        previousMonthBalance: previousMonthBalance,
        previousMonthCategories: previousMonthCategories,
        previousMonthTotal: previousMonthTotal,
        previousMonthIncome: previousMonthIncome,
        previousMonthExpense: previousMonthExpense,
        expenses: expenses,
        incomes: incomes,
        expenseCategories: expenseCategories,
        incomeCategories: incomeCategories,
        dateRange: _dateRange,
        periodTitle: periodTitle,
        dailyExpensesMap: dailyExpensesMap,
        dailyIncomesMap: dailyIncomesMap,
      ));
    } catch (e) {
      emit(MonthlySummaryError('Failed to update summary: ${e.toString()}'));
    }
  }

  void selectMonth(DateTime month, BuildContext context) {
    _selectedMonth = month;
    _dateRange = null; // Clear any date range when selecting a specific month
    loadMonthlySummary(context);
  }

  void selectDateRange(DateTimeRange dateRange, BuildContext context) {
    _dateRange = dateRange;
    // Setting _selectedMonth will be ignored as _dateRange has priority
    loadMonthlySummary(context);
  }

  void resetToCurrentMonth(BuildContext context) {
    _selectedMonth = DateTime.now();
    _dateRange = null;
    loadMonthlySummary(context);
  }

  @override
  Future<void> close() async {
    await _expensesSubscription?.cancel();
    await _incomesSubscription?.cancel();
    return super.close();
  }
}

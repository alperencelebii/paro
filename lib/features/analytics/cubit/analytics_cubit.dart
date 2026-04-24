import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/income_model.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../data/repositories/income_repository.dart';
import 'analytics_state.dart';

class AnalyticsCubit extends Cubit<AnalyticsState> {
  final ExpenseRepository _expenseRepository;
  final IncomeRepository _incomeRepository;

  AnalyticsCubit({
    required ExpenseRepository expenseRepository,
    required IncomeRepository incomeRepository,
  })  : _expenseRepository = expenseRepository,
        _incomeRepository = incomeRepository,
        super(AnalyticsInitial());

  Future<void> loadAnalytics({TimeFrame timeFrame = TimeFrame.month}) async {
    emit(AnalyticsLoading());

    try {
      final expenses = await _expenseRepository.getExpenses();
      final incomes = await _incomeRepository.getIncomes();

      if (expenses.isEmpty && incomes.isEmpty) {
        emit(AnalyticsLoaded(
          totalExpenses: 0,
          totalIncomes: 0,
          allExpenses: const [],
          allIncomes: const [],
          selectedTimeFrame: TimeFrame.month,
          dailyExpenses: const [],
          dailyIncomes: const [],
          categoryExpenses: const [],
          categoryIncomes: const [],
          selectedMonth: DateTime.now(),
        ));
        return;
      }

      // Calculate total expenses and incomes
      final totalExpenses =
          expenses.fold(0.0, (sum, expense) => sum + expense.amount);
      final totalIncomes =
          incomes.fold(0.0, (sum, income) => sum + income.amount);

      // Current month
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);

      // Filter expenses for current month
      final monthExpenses = expenses.where((expense) {
        final expenseMonth = DateTime(expense.date.year, expense.date.month);
        return expenseMonth.isAtSameMomentAs(currentMonth);
      }).toList();

      // Filter incomes for current month
      final monthIncomes = incomes.where((income) {
        final incomeMonth = DateTime(income.date.year, income.date.month);
        return incomeMonth.isAtSameMomentAs(currentMonth);
      }).toList();

      // Process expenses by day
      final Map<int, double> dailyExpenseAmounts = {};
      final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
      for (int i = 1; i <= daysInMonth; i++) {
        dailyExpenseAmounts[i] = 0;
      }

      for (final expense in monthExpenses) {
        final day = expense.date.day;
        dailyExpenseAmounts[day] = (dailyExpenseAmounts[day] ?? 0) + expense.amount;
      }

      final maxDailyExpenseAmount =
          dailyExpenseAmounts.values.fold(0.0, (a, b) => max<double>(a, b));

      final List<DailyExpense> dailyExpenses = [];
      dailyExpenseAmounts.forEach((day, amount) {
        final percentage =
            maxDailyExpenseAmount > 0 ? (amount / maxDailyExpenseAmount) * 100 : 0.0;

        dailyExpenses.add(DailyExpense(
          date: DateTime(now.year, now.month, day),
          amount: amount,
          percentage: percentage,
        ));
      });

      dailyExpenses.sort((a, b) => a.date.compareTo(b.date));

      // Process incomes by day
      final Map<int, double> dailyIncomeAmounts = {};
      for (int i = 1; i <= daysInMonth; i++) {
        dailyIncomeAmounts[i] = 0;
      }

      for (final income in monthIncomes) {
        final day = income.date.day;
        dailyIncomeAmounts[day] = (dailyIncomeAmounts[day] ?? 0) + income.amount;
      }

      final maxDailyIncomeAmount =
          dailyIncomeAmounts.values.fold(0.0, (a, b) => max<double>(a, b));

      final List<DailyIncome> dailyIncomes = [];
      dailyIncomeAmounts.forEach((day, amount) {
        final percentage =
            maxDailyIncomeAmount > 0 ? (amount / maxDailyIncomeAmount) * 100 : 0.0;

        dailyIncomes.add(DailyIncome(
          date: DateTime(now.year, now.month, day),
          amount: amount,
          percentage: percentage,
        ));
      });

      dailyIncomes.sort((a, b) => a.date.compareTo(b.date));

      // Process expenses by category
      final Map<ExpenseCategory, double> categoryExpenseAmounts = {};
      for (final category in ExpenseCategory.values) {
        categoryExpenseAmounts[category] = 0;
      }

      for (final expense in monthExpenses) {
        categoryExpenseAmounts[expense.category] =
            (categoryExpenseAmounts[expense.category] ?? 0) + expense.amount;
      }

      final totalMonthlyExpenseAmount =
          categoryExpenseAmounts.values.fold(0.0, (sum, amount) => sum + amount);

      final List<CategoryExpense> categoryExpenses = [];
      categoryExpenseAmounts.forEach((category, amount) {
        if (amount > 0) {
          final percentage = totalMonthlyExpenseAmount > 0
              ? (amount / totalMonthlyExpenseAmount) * 100
              : 0.0;

          categoryExpenses.add(CategoryExpense(
            category: category,
            amount: amount,
            percentage: percentage,
          ));
        }
      });

      categoryExpenses.sort((a, b) => b.amount.compareTo(a.amount));

      // Process incomes by category
      final Map<IncomeCategory, double> categoryIncomeAmounts = {};
      for (final category in IncomeCategory.values) {
        categoryIncomeAmounts[category] = 0;
      }

      for (final income in monthIncomes) {
        categoryIncomeAmounts[income.category] =
            (categoryIncomeAmounts[income.category] ?? 0) + income.amount;
      }

      final totalMonthlyIncomeAmount =
          categoryIncomeAmounts.values.fold(0.0, (sum, amount) => sum + amount);

      final List<CategoryIncome> categoryIncomes = [];
      categoryIncomeAmounts.forEach((category, amount) {
        if (amount > 0) {
          final percentage = totalMonthlyIncomeAmount > 0
              ? (amount / totalMonthlyIncomeAmount) * 100
              : 0.0;

          categoryIncomes.add(CategoryIncome(
            category: category,
            amount: amount,
            percentage: percentage,
          ));
        }
      });

      categoryIncomes.sort((a, b) => b.amount.compareTo(a.amount));

      emit(AnalyticsLoaded(
        totalExpenses: totalExpenses,
        totalIncomes: totalIncomes,
        allExpenses: expenses,
        allIncomes: incomes,
        selectedTimeFrame: timeFrame,
        dailyExpenses: dailyExpenses,
        dailyIncomes: dailyIncomes,
        categoryExpenses: categoryExpenses,
        categoryIncomes: categoryIncomes,
        selectedMonth: currentMonth,
      ));
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }

  Future<void> changeTimeFrame(TimeFrame timeFrame) async {
    final currentState = state;
    if (currentState is AnalyticsLoaded) {
      emit(currentState.copyWith(selectedTimeFrame: timeFrame));
    } else {
      await loadAnalytics(timeFrame: timeFrame);
    }
  }

  Future<void> changeMonth(DateTime month) async {
    // This would filter expenses for the selected month
    // For now, just updating the selected month
    final currentState = state;
    if (currentState is AnalyticsLoaded) {
      emit(currentState.copyWith(selectedMonth: month));
      // In a real implementation, we would reload data for this month
      await loadAnalytics();
    }
  }
}

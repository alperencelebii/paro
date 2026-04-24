import 'package:finance_track/features/monthly_summary/models/transaction_item.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'dart:math' as math;

import '../../../data/models/expense_model.dart';
import '../../../data/models/income_model.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../data/repositories/income_repository.dart';

part 'category_analysis_event.dart';
part 'category_analysis_state.dart';

// Bloc
class CategoryAnalysisBloc
    extends Bloc<CategoryAnalysisEvent, CategoryAnalysisState> {
  final ExpenseRepository expenseRepository;
  final IncomeRepository incomeRepository;

  // Persist user selections across reloads and while in loading state
  int _cachedTimeFrame = 365;
  bool _cachedShowExpense = true;
  bool _cachedShowIncome = true;

  CategoryAnalysisBloc({
    required this.expenseRepository,
    required this.incomeRepository,
  }) : super(CategoryAnalysisInitial()) {
    on<LoadCategoryAnalysis>(_onLoadCategoryAnalysis);
    on<UpdateTimeFrame>(_onUpdateTimeFrame);
    on<ToggleDataType>(_onToggleDataType);
    on<LoadCategoryDetail>(_onLoadCategoryDetail);
    on<FilterCategoryData>(_onFilterCategoryData);
    on<CompareCategoryPeriods>(_onCompareCategoryPeriods);
    on<CalculatePrediction>(_onCalculatePrediction);
  }

  Future<void> _onLoadCategoryAnalysis(
    LoadCategoryAnalysis event,
    Emitter<CategoryAnalysisState> emit,
  ) async {
    // Capture previous state BEFORE emitting loading so we can preserve settings
    final previousState = state;
    emit(CategoryAnalysisLoading());
    try {
      // Preserve previously selected settings if available
      int timeFrame = _cachedTimeFrame;
      bool showExpense = _cachedShowExpense;
      bool showIncome = _cachedShowIncome;

      if (previousState is CategoryAnalysisLoaded) {
        timeFrame = previousState.timeFrame;
        showExpense = previousState.showExpense;
        showIncome = previousState.showIncome;
      }

      // Update caches before load so concurrent reloads keep values
      _cachedTimeFrame = timeFrame;
      _cachedShowExpense = showExpense;
      _cachedShowIncome = showIncome;

      await _loadCategoryData(
        emit,
        timeFrame,
        showExpense,
        showIncome,
      );
    } catch (e) {
      emit(CategoryAnalysisError('Failed to load category analysis: $e'));
    }
  }

  Future<void> _onUpdateTimeFrame(
    UpdateTimeFrame event,
    Emitter<CategoryAnalysisState> emit,
  ) async {
    if (state is CategoryAnalysisLoaded) {
      final currentState = state as CategoryAnalysisLoaded;
      emit(CategoryAnalysisLoading());
      try {
        _cachedTimeFrame = event.timeFrame;
        _cachedShowExpense = currentState.showExpense;
        _cachedShowIncome = currentState.showIncome;
        await _loadCategoryData(
          emit,
          event.timeFrame,
          currentState.showExpense,
          currentState.showIncome,
        );
      } catch (e) {
        emit(CategoryAnalysisError('Failed to update time frame: $e'));
      }
    }
  }

  void _onToggleDataType(
    ToggleDataType event,
    Emitter<CategoryAnalysisState> emit,
  ) {
    if (state is CategoryAnalysisLoaded) {
      final currentState = state as CategoryAnalysisLoaded;
      _cachedShowExpense = event.showExpense;
      _cachedShowIncome = event.showIncome;
      emit(currentState.copyWith(
        showExpense: event.showExpense,
        showIncome: event.showIncome,
      ));
    }
  }

  Future<void> _onLoadCategoryDetail(
    LoadCategoryDetail event,
    Emitter<CategoryAnalysisState> emit,
  ) async {
    emit(CategoryAnalysisLoading());
    try {
      final now = DateTime.now();
      DateTimeRange dateRange;

      if (event.dateRange != null) {
        dateRange = event.dateRange!;
      } else if (event.timeFrame > 0) {
        dateRange = DateTimeRange(
          start: now.subtract(Duration(days: event.timeFrame)),
          end: now,
        );
      } else {
        // Default to last 30 days if nothing specified
        dateRange = DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
      }

      if (event.isExpense) {
        await _loadExpenseCategoryDetail(
            event.category, dateRange, event.timeFrame, emit);
      } else {
        await _loadIncomeCategoryDetail(
            event.category, dateRange, event.timeFrame, emit);
      }
    } catch (e) {
      emit(CategoryAnalysisError('Failed to load category detail: $e'));
    }
  }

  Future<void> _loadExpenseCategoryDetail(
    dynamic category,
    DateTimeRange dateRange,
    int timeFrame,
    Emitter<CategoryAnalysisState> emit,
  ) async {
    // Get all expenses
    final allExpenses = await expenseRepository.getExpenses();

    // Filter expenses by category and date range
    final categoryExpenses = allExpenses.where((e) {
      final inRange = e.date.isAfter(dateRange.start) &&
          e.date.isBefore(dateRange.end.add(const Duration(days: 1)));
      if (!inRange) return false;

      if (category is ExpenseCategory) {
        return e.category == category;
      }

      // Custom category by name
      if (category is String) {
        return e.usesCustomCategory && e.customCategoryName == category;
      }

      return false;
    }).toList();

    // Calculate total and average
    double totalAmount = 0;
    for (final expense in categoryExpenses) {
      totalAmount += expense.amount;
    }

    final averageAmount = categoryExpenses.isNotEmpty
        ? totalAmount / categoryExpenses.length
        : 0.0;

    // Calculate percentage of total expenses
    final allExpensesInPeriod = allExpenses
        .where((e) =>
            e.date.isAfter(dateRange.start) &&
            e.date.isBefore(dateRange.end.add(const Duration(days: 1))))
        .toList();

    double totalExpenses = 0;
    for (final expense in allExpensesInPeriod) {
      totalExpenses += expense.amount;
    }

    final percentageOfTotal =
        totalExpenses > 0 ? (totalAmount / totalExpenses) * 100 : 0.0;

    // Generate periodic data for charts
    final periodicData = _generatePeriodicData(
        dateRange, categoryExpenses.cast<dynamic>(), true);

    // Sort transactions by date (newest first)
    categoryExpenses.sort((a, b) => b.date.compareTo(a.date));

    emit(CategoryDetailLoaded(
      category: category,
      isExpense: true,
      totalAmount: totalAmount,
      averageAmount: averageAmount,
      transactionCount: categoryExpenses.length,
      percentageOfTotal: percentageOfTotal,
      periodicData: periodicData,
      transactions:
          categoryExpenses.map((e) => TransactionItem.fromExpense(e)).toList(),
      timeFrame: timeFrame,
      dateRange: dateRange,
    ));
  }

  Future<void> _loadIncomeCategoryDetail(
    dynamic category,
    DateTimeRange dateRange,
    int timeFrame,
    Emitter<CategoryAnalysisState> emit,
  ) async {
    // Get all incomes
    final allIncomes = await incomeRepository.getIncomes();

    // Filter incomes by category and date range
    final categoryIncomes = allIncomes.where((i) {
      final inRange = i.date.isAfter(dateRange.start) &&
          i.date.isBefore(dateRange.end.add(const Duration(days: 1)));
      if (!inRange) return false;

      if (category is IncomeCategory) {
        return i.category == category;
      }

      // For income, custom categories are not modeled; fall back to name match if any
      if (category is String) {
        return false; // No custom income categories currently
      }

      return false;
    }).toList();

    // Calculate total and average
    double totalAmount = 0;
    for (final income in categoryIncomes) {
      totalAmount += income.amount;
    }

    final averageAmount =
        categoryIncomes.isNotEmpty ? totalAmount / categoryIncomes.length : 0.0;

    // Calculate percentage of total incomes
    final allIncomesInPeriod = allIncomes
        .where((i) =>
            i.date.isAfter(dateRange.start) &&
            i.date.isBefore(dateRange.end.add(const Duration(days: 1))))
        .toList();

    double totalIncomes = 0;
    for (final income in allIncomesInPeriod) {
      totalIncomes += income.amount;
    }

    final percentageOfTotal =
        totalIncomes > 0 ? (totalAmount / totalIncomes) * 100 : 0.0;

    // Generate periodic data for charts
    final periodicData = _generatePeriodicData(
        dateRange, categoryIncomes.cast<dynamic>(), false);

    // Sort transactions by date (newest first)
    categoryIncomes.sort((a, b) => b.date.compareTo(a.date));

    emit(CategoryDetailLoaded(
      category: category,
      isExpense: false,
      totalAmount: totalAmount,
      averageAmount: averageAmount,
      transactionCount: categoryIncomes.length,
      percentageOfTotal: percentageOfTotal,
      periodicData: periodicData,
      transactions:
          categoryIncomes.map((e) => TransactionItem.fromIncome(e)).toList(),
      timeFrame: timeFrame,
      dateRange: dateRange,
    ));
  }

  List<PeriodicData> _generatePeriodicData(
    DateTimeRange dateRange,
    List<dynamic> transactions,
    bool isExpense,
  ) {
    // Determine the appropriate interval based on the date range duration
    final duration = dateRange.end.difference(dateRange.start).inDays;

    if (transactions.isEmpty) {
      return [];
    }

    if (duration <= 31) {
      // Daily data for ranges up to a month
      return _generateDailyData(dateRange, transactions, isExpense);
    } else if (duration <= 90) {
      // Weekly data for ranges up to 3 months
      return _generateWeeklyData(dateRange, transactions, isExpense);
    } else {
      // Monthly data for longer ranges
      return _generateMonthlyData(dateRange, transactions, isExpense);
    }
  }

  List<PeriodicData> _generateDailyData(
    DateTimeRange dateRange,
    List<dynamic> transactions,
    bool isExpense,
  ) {
    final dailyData = <DateTime, double>{};

    // Initialize all days with zero
    final days = dateRange.end.difference(dateRange.start).inDays;
    for (int i = 0; i <= days; i++) {
      final date = DateTime(
        dateRange.start.year,
        dateRange.start.month,
        dateRange.start.day,
      ).add(Duration(days: i));

      dailyData[date] = 0;
    }

    // Populate with actual data
    for (final transaction in transactions) {
      final date = isExpense
          ? (transaction as Expense).date
          : (transaction as Income).date;

      // Normalize date to start of day
      final normalizedDate = DateTime(
        date.year,
        date.month,
        date.day,
      );

      final amount = isExpense
          ? (transaction as Expense).amount
          : (transaction as Income).amount;

      dailyData[normalizedDate] = (dailyData[normalizedDate] ?? 0) + amount;
    }

    // Convert map to list and sort by date
    final result = dailyData.entries
        .map((e) => PeriodicData(date: e.key, amount: e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return result;
  }

  List<PeriodicData> _generateWeeklyData(
    DateTimeRange dateRange,
    List<dynamic> transactions,
    bool isExpense,
  ) {
    final weeklyData = <DateTime, double>{};

    // Initialize all weeks with zero
    DateTime current = _getStartOfWeek(dateRange.start);
    final end = dateRange.end;

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      weeklyData[current] = 0;
      current = current.add(const Duration(days: 7));
    }

    // Populate with actual data
    for (final transaction in transactions) {
      final date = isExpense
          ? (transaction as Expense).date
          : (transaction as Income).date;

      // Get week start
      final weekStart = _getStartOfWeek(date);

      final amount = isExpense
          ? (transaction as Expense).amount
          : (transaction as Income).amount;

      weeklyData[weekStart] = (weeklyData[weekStart] ?? 0) + amount;
    }

    // Convert map to list and sort by date
    final result = weeklyData.entries
        .map((e) => PeriodicData(date: e.key, amount: e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return result;
  }

  List<PeriodicData> _generateMonthlyData(
    DateTimeRange dateRange,
    List<dynamic> transactions,
    bool isExpense,
  ) {
    final monthlyData = <DateTime, double>{};

    // Initialize all months with zero
    DateTime current = DateTime(dateRange.start.year, dateRange.start.month, 1);
    final end = DateTime(dateRange.end.year, dateRange.end.month, 1);

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      monthlyData[current] = 0;
      current = DateTime(
        current.year + (current.month == 12 ? 1 : 0),
        current.month == 12 ? 1 : current.month + 1,
        1,
      );
    }

    // Populate with actual data
    for (final transaction in transactions) {
      final date = isExpense
          ? (transaction as Expense).date
          : (transaction as Income).date;

      // Get month start
      final monthStart = DateTime(date.year, date.month, 1);

      final amount = isExpense
          ? (transaction as Expense).amount
          : (transaction as Income).amount;

      monthlyData[monthStart] = (monthlyData[monthStart] ?? 0) + amount;
    }

    // Convert map to list and sort by date
    final result = monthlyData.entries
        .map((e) => PeriodicData(date: e.key, amount: e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return result;
  }

  DateTime _getStartOfWeek(DateTime date) {
    // Get the start of the week (assuming Monday is the first day)
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  Future<void> _loadCategoryData(
    Emitter<CategoryAnalysisState> emit,
    int timeFrame, [
    bool showExpense = true,
    bool showIncome = true,
  ]) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: timeFrame));

    // Get expenses and incomes for the selected period
    final expenses = await expenseRepository.getExpenses();
    final filteredExpenses = expenses
        .where((expense) =>
            expense.date.isAfter(startDate) &&
            expense.date.isBefore(now.add(const Duration(days: 1))))
        .toList();

    final incomes = await incomeRepository.getIncomes();
    final filteredIncomes = incomes
        .where((income) =>
            income.date.isAfter(startDate) &&
            income.date.isBefore(now.add(const Duration(days: 1))))
        .toList();

    // Process expenses by category (built-ins) and by custom category name
    final Map<ExpenseCategory, double> expenseCategoriesAmount = {};
    final Map<String, double> customExpenseCategoriesAmount = {};
    double totalExpenses = 0;

    for (final expense in filteredExpenses) {
      if (expense.usesCustomCategory) {
        final name = expense.customCategoryName ?? 'Other';
        customExpenseCategoriesAmount[name] =
            (customExpenseCategoriesAmount[name] ?? 0) + expense.amount;
      } else {
        final category = expense.category;
        expenseCategoriesAmount[category] =
            (expenseCategoriesAmount[category] ?? 0) + expense.amount;
      }
      totalExpenses += expense.amount;
    }

    // Calculate expense percentages
    final Map<ExpenseCategory, double> expenseCategoriesPercentage = {};
    final Map<String, double> customExpenseCategoriesPercentage = {};
    if (totalExpenses > 0) {
      expenseCategoriesAmount.forEach((category, amount) {
        expenseCategoriesPercentage[category] = (amount / totalExpenses) * 100;
      });
      customExpenseCategoriesAmount.forEach((name, amount) {
        customExpenseCategoriesPercentage[name] =
            (amount / totalExpenses) * 100;
      });
    }

    // Process incomes by category
    final Map<IncomeCategory, double> incomeCategoriesAmount = {};
    double totalIncomes = 0;

    for (final income in filteredIncomes) {
      final category = income.category;
      incomeCategoriesAmount[category] =
          (incomeCategoriesAmount[category] ?? 0) + income.amount;
      totalIncomes += income.amount;
    }

    // Calculate income percentages
    final Map<IncomeCategory, double> incomeCategoriesPercentage = {};
    if (totalIncomes > 0) {
      incomeCategoriesAmount.forEach((category, amount) {
        incomeCategoriesPercentage[category] = (amount / totalIncomes) * 100;
      });
    }

    // Merge custom expenses into dynamic map for UI compatibility
    final Map<dynamic, double> mergedExpenseAmounts = {
      ...expenseCategoriesAmount,
      ...customExpenseCategoriesAmount,
    };

    // For percentages, keep only the ones that match keys in merged
    final Map<dynamic, double> mergedExpensePercentages = {
      ...expenseCategoriesPercentage,
      ...customExpenseCategoriesPercentage,
    };

    emit(CategoryAnalysisLoaded(
      expenseCategoriesAmount: mergedExpenseAmounts,
      incomeCategoriesAmount: incomeCategoriesAmount,
      expenseCategoriesPercentage: mergedExpensePercentages,
      incomeCategoriesPercentage: incomeCategoriesPercentage,
      totalExpenses: totalExpenses,
      totalIncomes: totalIncomes,
      timeFrame: timeFrame,
      showExpense: showExpense,
      showIncome: showIncome,
    ));
  }

  Future<void> _onFilterCategoryData(
    FilterCategoryData event,
    Emitter<CategoryAnalysisState> emit,
  ) async {
    emit(CategoryAnalysisLoading());
    try {
      final DateTimeRange dateRange = event.customDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          );

      List<dynamic> transactions = [];
      dynamic category;
      bool isExpense = false;

      // Get transactions for all categories or specific categories
      if (event.selectedCategories != null &&
          event.selectedCategories!.isNotEmpty) {
        for (final cat in event.selectedCategories!) {
          if (cat is ExpenseCategory) {
            final expenses = await expenseRepository.getExpenses();
            transactions.addAll(expenses.where((e) => e.category == cat));
            isExpense = true;
            category = cat;
          } else if (cat is IncomeCategory) {
            final incomes = await incomeRepository.getIncomes();
            transactions.addAll(incomes.where((i) => i.category == cat));
            isExpense = false;
            category = cat;
          }
        }
      } else {
        // Get all transactions if no categories specified
        if (state is CategoryDetailLoaded) {
          final detailState = state as CategoryDetailLoaded;
          category = detailState.category;
          isExpense = detailState.isExpense;

          if (isExpense) {
            final expenses = await expenseRepository.getExpenses();
            transactions =
                expenses.where((e) => e.category == category).toList();
          } else {
            final incomes = await incomeRepository.getIncomes();
            transactions =
                incomes.where((i) => i.category == category).toList();
          }
        } else {
          emit(const CategoryAnalysisError(
              'No category selected for filtering'));
          return;
        }
      }

      // Filter by date range
      transactions = transactions.where((t) {
        final date = isExpense ? (t as Expense).date : (t as Income).date;
        return date.isAfter(dateRange.start) &&
            date.isBefore(dateRange.end.add(const Duration(days: 1)));
      }).toList();

      // Filter by amount if specified
      if (event.minAmount != null) {
        transactions = transactions.where((t) {
          final amount =
              isExpense ? (t as Expense).amount : (t as Income).amount;
          return amount >= event.minAmount!;
        }).toList();
      }

      if (event.maxAmount != null) {
        transactions = transactions.where((t) {
          final amount =
              isExpense ? (t as Expense).amount : (t as Income).amount;
          return amount <= event.maxAmount!;
        }).toList();
      }

      // Calculate total amount
      double totalAmount = 0;
      for (final transaction in transactions) {
        final amount = isExpense
            ? (transaction as Expense).amount
            : (transaction as Income).amount;
        totalAmount += amount;
      }

      // Sort transactions by date (newest first)
      transactions.sort((a, b) {
        final dateA = isExpense ? (a as Expense).date : (a as Income).date;
        final dateB = isExpense ? (b as Expense).date : (b as Income).date;
        return dateB.compareTo(dateA);
      });

      emit(CategoryFilteredData(
        category: category,
        isExpense: isExpense,
        filteredTransactions: transactions,
        totalFilteredAmount: totalAmount,
        filteredDateRange: dateRange,
        minAmount: event.minAmount,
        maxAmount: event.maxAmount,
      ));
    } catch (e) {
      emit(CategoryAnalysisError('Failed to filter category data: $e'));
    }
  }

  Future<void> _onCompareCategoryPeriods(
    CompareCategoryPeriods event,
    Emitter<CategoryAnalysisState> emit,
  ) async {
    emit(CategoryAnalysisLoading());
    try {
      List<dynamic> firstPeriodTransactions = [];
      List<dynamic> secondPeriodTransactions = [];

      if (event.isExpense) {
        final allExpenses = await expenseRepository.getExpenses();

        // Filter for first period
        firstPeriodTransactions = allExpenses
            .where((e) =>
                e.category == event.category &&
                e.date.isAfter(event.firstPeriod.start) &&
                e.date.isBefore(
                    event.firstPeriod.end.add(const Duration(days: 1))))
            .toList();

        // Filter for second period
        secondPeriodTransactions = allExpenses
            .where((e) =>
                e.category == event.category &&
                e.date.isAfter(event.secondPeriod.start) &&
                e.date.isBefore(
                    event.secondPeriod.end.add(const Duration(days: 1))))
            .toList();
      } else {
        final allIncomes = await incomeRepository.getIncomes();

        // Filter for first period
        firstPeriodTransactions = allIncomes
            .where((i) =>
                i.category == event.category &&
                i.date.isAfter(event.firstPeriod.start) &&
                i.date.isBefore(
                    event.firstPeriod.end.add(const Duration(days: 1))))
            .toList();

        // Filter for second period
        secondPeriodTransactions = allIncomes
            .where((i) =>
                i.category == event.category &&
                i.date.isAfter(event.secondPeriod.start) &&
                i.date.isBefore(
                    event.secondPeriod.end.add(const Duration(days: 1))))
            .toList();
      }

      // Calculate totals
      double firstPeriodAmount = 0;
      for (final transaction in firstPeriodTransactions) {
        firstPeriodAmount += event.isExpense
            ? (transaction as Expense).amount
            : (transaction as Income).amount;
      }

      double secondPeriodAmount = 0;
      for (final transaction in secondPeriodTransactions) {
        secondPeriodAmount += event.isExpense
            ? (transaction as Expense).amount
            : (transaction as Income).amount;
      }

      // Calculate percentage change
      double percentageChange = 0;
      if (firstPeriodAmount > 0) {
        percentageChange =
            ((secondPeriodAmount - firstPeriodAmount) / firstPeriodAmount) *
                100;
      }

      // Generate periodic data for charts
      final firstPeriodData = _generatePeriodicData(
        event.firstPeriod,
        firstPeriodTransactions,
        event.isExpense,
      );

      final secondPeriodData = _generatePeriodicData(
        event.secondPeriod,
        secondPeriodTransactions,
        event.isExpense,
      );

      emit(CategoryComparisonLoaded(
        category: event.category,
        isExpense: event.isExpense,
        firstPeriod: event.firstPeriod,
        secondPeriod: event.secondPeriod,
        firstPeriodAmount: firstPeriodAmount,
        secondPeriodAmount: secondPeriodAmount,
        firstPeriodCount: firstPeriodTransactions.length,
        secondPeriodCount: secondPeriodTransactions.length,
        percentageChange: percentageChange,
        firstPeriodData: firstPeriodData,
        secondPeriodData: secondPeriodData,
      ));
    } catch (e) {
      emit(CategoryAnalysisError('Failed to compare periods: $e'));
    }
  }

  Future<void> _onCalculatePrediction(
    CalculatePrediction event,
    Emitter<CategoryAnalysisState> emit,
  ) async {
    emit(CategoryAnalysisLoading());
    try {
      final now = DateTime.now();

      // Get historical data (last 12 months)
      final startDate = DateTime(now.year - 1, now.month, now.day);
      final dateRange = DateTimeRange(start: startDate, end: now);

      List<dynamic> transactions = [];

      if (event.isExpense) {
        final allExpenses = await expenseRepository.getExpenses();
        transactions = allExpenses
            .where((e) =>
                e.category == event.category &&
                e.date.isAfter(startDate) &&
                e.date.isBefore(now.add(const Duration(days: 1))))
            .toList();
      } else {
        final allIncomes = await incomeRepository.getIncomes();
        transactions = allIncomes
            .where((i) =>
                i.category == event.category &&
                i.date.isAfter(startDate) &&
                i.date.isBefore(now.add(const Duration(days: 1))))
            .toList();
      }

      // Generate monthly historical data
      final historicalData =
          _generateMonthlyData(dateRange, transactions, event.isExpense);

      // Calculate average monthly amount
      double totalAmount = 0;
      for (final dataPoint in historicalData) {
        totalAmount += dataPoint.amount;
      }

      final averageMonthlyAmount = historicalData.isNotEmpty
          ? (totalAmount / historicalData.length).toDouble()
          : 0.0;

      // Calculate variance and seasonality for confidence score
      double variance = 0;
      if (historicalData.length > 1) {
        double sumOfSquaredDifferences = 0;
        for (final dataPoint in historicalData) {
          sumOfSquaredDifferences +=
              math.pow(dataPoint.amount - averageMonthlyAmount, 2).toDouble();
        }
        variance = sumOfSquaredDifferences / historicalData.length;
      }

      // Calculate confidence score (higher variance = lower confidence)
      // Normalize to 0-100% range
      double confidenceScore = 100;
      if (averageMonthlyAmount > 0) {
        final coefficientOfVariation =
            math.sqrt(variance).toDouble() / averageMonthlyAmount;
        confidenceScore =
            math.max<double>(0, 100 - (coefficientOfVariation * 100));

        // Adjust based on amount of historical data (more data = higher confidence)
        final dataFactor = math.min<double>(1.0, historicalData.length / 12);
        confidenceScore = confidenceScore * dataFactor;
      }

      // Generate predicted data for the next few months
      final List<PeriodicData> predictedData = [];

      // Get the last month in historical data
      DateTime lastMonth = now;
      if (historicalData.isNotEmpty) {
        lastMonth = historicalData.last.date;
      }

      // Use simple time series prediction based on moving average with seasonality
      for (int i = 1; i <= event.predictionMonths; i++) {
        final predictedMonth = DateTime(lastMonth.year, lastMonth.month + i, 1);

        // Base prediction on average
        double predictedAmount = averageMonthlyAmount;

        // Apply seasonality if we have enough data
        if (historicalData.length >= 12) {
          // Check same month in previous year
          final sameMonthPreviousYear = historicalData.firstWhere(
            (data) =>
                data.date.month == predictedMonth.month &&
                data.date.year == predictedMonth.year - 1,
            orElse: () => PeriodicData(
                date: predictedMonth, amount: averageMonthlyAmount.toDouble()),
          );

          // Weight seasonality factor
          const seasonalityWeight = 0.3;
          final seasonalityFactor =
              sameMonthPreviousYear.amount / averageMonthlyAmount;

          // Apply seasonality adjustment
          predictedAmount = averageMonthlyAmount *
              (1 + (seasonalityFactor - 1) * seasonalityWeight);
        }

        // Apply trend based on last 3 months if available
        if (historicalData.length >= 3) {
          final recentMonths =
              historicalData.sublist(historicalData.length - 3);
          double trendFactor = 0;

          // Calculate slope of recent trend
          for (int j = 1; j < recentMonths.length; j++) {
            trendFactor +=
                (recentMonths[j].amount - recentMonths[j - 1].amount) /
                    recentMonths[j - 1].amount;
          }
          trendFactor /= (recentMonths.length - 1);

          // Apply diminishing trend effect based on how far into the future
          final trendWeight = 0.5 / i.toDouble();
          predictedAmount = predictedAmount * (1 + trendFactor * trendWeight);
        }

        predictedData.add(PeriodicData(
          date: predictedMonth,
          amount: predictedAmount,
        ));
      }

      final predictedTotalAmount =
          predictedData.fold<double>(0, (sum, data) => sum + data.amount);

      emit(CategoryPredictionLoaded(
        category: event.category,
        isExpense: event.isExpense,
        historicalData: historicalData,
        predictedData: predictedData,
        projectedTotal: predictedTotalAmount,
        projectedAverage: averageMonthlyAmount.toDouble(),
        growthRate: 0.0, // Placeholder for growth rate
        trendDescription: '', // Placeholder for trend description
      ));
    } catch (e) {
      emit(CategoryAnalysisError('Failed to calculate prediction: $e'));
    }
  }
}

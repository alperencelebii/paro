import 'dart:async';
import 'package:finance_track/features/monthly_summary/models/transaction_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/expense_model.dart';
import '../../../data/models/income_model.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../data/repositories/income_repository.dart';
import 'transaction_analytics_event.dart';
import 'transaction_analytics_state.dart';

/// BLoC for transaction analytics
class TransactionAnalyticsBloc
    extends Bloc<TransactionAnalyticsEvent, TransactionAnalyticsState> {
  final ExpenseRepository _expenseRepository;
  final IncomeRepository _incomeRepository;

  TransactionAnalyticsBloc({
    required ExpenseRepository expenseRepository,
    required IncomeRepository incomeRepository,
  })  : _expenseRepository = expenseRepository,
        _incomeRepository = incomeRepository,
        super(const TransactionAnalyticsInitial()) {
    on<LoadTransactionAnalytics>(_onLoadTransactionAnalytics);
    on<FilterTransactionsByDateRange>(_onFilterTransactionsByDateRange);
    on<ClearDateRangeFilter>(_onClearDateRangeFilter);
    on<FilterTransactionsByAmountRange>(_onFilterTransactionsByAmountRange);
    on<ClearAmountFilter>(_onClearAmountFilter);
    on<FilterExpensesByCategory>(_onFilterExpensesByCategory);
    on<FilterIncomesByCategory>(_onFilterIncomesByCategory);
    on<SearchTransactions>(_onSearchTransactions);
    on<SortTransactions>(_onSortTransactions);
    on<ResetFilters>(_onResetFilters);
    on<ToggleTransactionType>(_onToggleTransactionType);
    on<SetGroupingOption>(_onSetGroupingOption);
    on<ToggleShowAllTransactions>(_onToggleShowAllTransactions);
  }

  /// Handle loading all transaction data
  Future<void> _onLoadTransactionAnalytics(
    LoadTransactionAnalytics event,
    Emitter<TransactionAnalyticsState> emit,
  ) async {
    emit(const TransactionAnalyticsLoading());

    try {
      // Load all expenses and incomes
      final expenses = await _expenseRepository.getAllExpenses();
      final incomes = await _incomeRepository.getAllIncomes();

      // Create unified transaction items
      final List<TransactionItem> transactions = [
        ...expenses.map((e) => TransactionItem.fromExpense(e)),
        ...incomes.map((i) => TransactionItem.fromIncome(i)),
      ];

      // Sort by date descending by default
      transactions.sort((a, b) => b.date.compareTo(a.date));

      // Group transactions by date
      final Map<DateTime, List<TransactionItem>> transactionsByDate = {};
      for (final transaction in transactions) {
        final date = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );
        if (!transactionsByDate.containsKey(date)) {
          transactionsByDate[date] = [];
        }
        transactionsByDate[date]!.add(transaction);
      }

      // Group transactions by category
      final Map<dynamic, List<TransactionItem>> transactionsByCategory = {};
      for (final transaction in transactions) {
        if (!transactionsByCategory.containsKey(transaction.category)) {
          transactionsByCategory[transaction.category] = [];
        }
        transactionsByCategory[transaction.category]!.add(transaction);
      }

      // Calculate totals by category
      final Map<String, double> categoryTotals = {};
      for (final entry in transactionsByCategory.entries) {
        final categoryName = entry.value.first.categoryName;
        final total = entry.value.fold<double>(
          0,
          (sum, item) => sum + item.amount,
        );
        categoryTotals[categoryName] = total;
      }

      // Calculate statistics
      final double totalExpenses = expenses.fold(
        0,
        (sum, expense) => sum + expense.amount,
      );

      final double totalIncomes = incomes.fold(
        0,
        (sum, income) => sum + income.amount,
      );

      final double netBalance = totalIncomes - totalExpenses;

      // Create amounts by category map
      final Map<dynamic, double> amountsByCategory = {};
      for (final category in transactionsByCategory.keys) {
        final amount = transactionsByCategory[category]!.fold<double>(
          0,
          (sum, item) => sum + item.amount,
        );
        amountsByCategory[category] = amount;
      }

      // Create amounts by date map
      final Map<DateTime, double> amountsByDate = {};
      for (final date in transactionsByDate.keys) {
        double expenseAmount = 0;
        double incomeAmount = 0;

        for (final transaction in transactionsByDate[date]!) {
          if (transaction.isExpense) {
            expenseAmount += transaction.amount;
          } else {
            incomeAmount += transaction.amount;
          }
        }

        // Store net amount (income - expense)
        amountsByDate[date] = incomeAmount - expenseAmount;
      }

      emit(TransactionAnalyticsLoaded(
        allExpenses: expenses,
        allIncomes: incomes,
        filteredTransactions: transactions,
        transactionsByDate: transactionsByDate,
        transactionsByCategory: transactionsByCategory,
        categoryTotals: categoryTotals,
        totalExpenses: totalExpenses,
        totalIncomes: totalIncomes,
        netBalance: netBalance,
        amountsByCategory: amountsByCategory,
        amountsByDate: amountsByDate,
      ));
    } catch (e) {
      emit(TransactionAnalyticsError('Failed to load transaction data: $e'));
    }
  }

  /// Handle filtering by date range
  void _onFilterTransactionsByDateRange(
    FilterTransactionsByDateRange event,
    Emitter<TransactionAnalyticsState> emit,
  ) {
    if (state is TransactionAnalyticsLoaded) {
      final currentState = state as TransactionAnalyticsLoaded;

      // Apply date filter to transactions
      final filteredTransactions = _applyAllFilters(
        expenses: currentState.allExpenses,
        incomes: currentState.allIncomes,
        dateRange: event.dateRange,
        minAmount: currentState.minAmount,
        maxAmount: currentState.maxAmount,
        expenseCategories: currentState.expenseCategories,
        incomeCategories: currentState.incomeCategories,
        searchQuery: currentState.searchQuery,
        transactionType: currentState.transactionType,
      );

      // Sort and update the filtered transactions
      final sortedTransactions = _sortTransactions(
        filteredTransactions,
        currentState.sortField,
        currentState.sortDirection,
      );

      // Update groupings
      final newGroupedData = _updateGroupedData(
        sortedTransactions,
        currentState.groupBy,
      );

      emit(currentState.copyWith(
        filteredTransactions: sortedTransactions,
        dateRange: event.dateRange,
        transactionsByDate: newGroupedData.transactionsByDate,
        transactionsByCategory: newGroupedData.transactionsByCategory,
        amountsByDate: newGroupedData.amountsByDate,
      ));
    }
  }

  /// Handle clearing the date range (set to null)
  void _onClearDateRangeFilter(
    ClearDateRangeFilter event,
    Emitter<TransactionAnalyticsState> emit,
  ) {
    if (state is TransactionAnalyticsLoaded) {
      final currentState = state as TransactionAnalyticsLoaded;

      final filteredTransactions = _applyAllFilters(
        expenses: currentState.allExpenses,
        incomes: currentState.allIncomes,
        dateRange: null,
        minAmount: currentState.minAmount,
        maxAmount: currentState.maxAmount,
        expenseCategories: currentState.expenseCategories,
        incomeCategories: currentState.incomeCategories,
        searchQuery: currentState.searchQuery,
        transactionType: currentState.transactionType,
      );

      final sortedTransactions = _sortTransactions(
        filteredTransactions,
        currentState.sortField,
        currentState.sortDirection,
      );

      final newGroupedData = _updateGroupedData(
        sortedTransactions,
        currentState.groupBy,
      );

      emit(currentState.copyWith(
        filteredTransactions: sortedTransactions,
        transactionsByDate: newGroupedData.transactionsByDate,
        transactionsByCategory: newGroupedData.transactionsByCategory,
        amountsByDate: newGroupedData.amountsByDate,
        setDateRangeNull: true,
      ));
    }
  }

  /// Handle filtering by amount range
  void _onFilterTransactionsByAmountRange(
    FilterTransactionsByAmountRange event,
    Emitter<TransactionAnalyticsState> emit,
  ) {
    if (state is TransactionAnalyticsLoaded) {
      final currentState = state as TransactionAnalyticsLoaded;

      // Apply amount filter to transactions
      final filteredTransactions = _applyAllFilters(
        expenses: currentState.allExpenses,
        incomes: currentState.allIncomes,
        dateRange: currentState.dateRange,
        minAmount: event.minAmount,
        maxAmount: event.maxAmount,
        expenseCategories: currentState.expenseCategories,
        incomeCategories: currentState.incomeCategories,
        searchQuery: currentState.searchQuery,
        transactionType: currentState.transactionType,
      );

      // Sort and update the filtered transactions
      final sortedTransactions = _sortTransactions(
        filteredTransactions,
        currentState.sortField,
        currentState.sortDirection,
      );

      // Update groupings
      final newGroupedData = _updateGroupedData(
        sortedTransactions,
        currentState.groupBy,
      );

      emit(currentState.copyWith(
        filteredTransactions: sortedTransactions,
        minAmount: event.minAmount,
        maxAmount: event.maxAmount,
        transactionsByDate: newGroupedData.transactionsByDate,
        transactionsByCategory: newGroupedData.transactionsByCategory,
        amountsByDate: newGroupedData.amountsByDate,
      ));
    }
  }

  /// Handle clearing the amount range (set min/max to null)
  void _onClearAmountFilter(
    ClearAmountFilter event,
    Emitter<TransactionAnalyticsState> emit,
  ) {
    if (state is TransactionAnalyticsLoaded) {
      final currentState = state as TransactionAnalyticsLoaded;

      final filteredTransactions = _applyAllFilters(
        expenses: currentState.allExpenses,
        incomes: currentState.allIncomes,
        dateRange: currentState.dateRange,
        minAmount: null,
        maxAmount: null,
        expenseCategories: currentState.expenseCategories,
        incomeCategories: currentState.incomeCategories,
        searchQuery: currentState.searchQuery,
        transactionType: currentState.transactionType,
      );

      final sortedTransactions = _sortTransactions(
        filteredTransactions,
        currentState.sortField,
        currentState.sortDirection,
      );

      final newGroupedData = _updateGroupedData(
        sortedTransactions,
        currentState.groupBy,
      );

      emit(currentState.copyWith(
        filteredTransactions: sortedTransactions,
        transactionsByDate: newGroupedData.transactionsByDate,
        transactionsByCategory: newGroupedData.transactionsByCategory,
        amountsByDate: newGroupedData.amountsByDate,
        setMinAmountNull: true,
        setMaxAmountNull: true,
      ));
    }
  }

  /// Handle filtering expenses by category
  void _onFilterExpensesByCategory(
    FilterExpensesByCategory event,
    Emitter<TransactionAnalyticsState> emit,
  ) {
    if (state is TransactionAnalyticsLoaded) {
      final currentState = state as TransactionAnalyticsLoaded;

      // Apply expense category filter
      final filteredTransactions = _applyAllFilters(
        expenses: currentState.allExpenses,
        incomes: currentState.allIncomes,
        dateRange: currentState.dateRange,
        minAmount: currentState.minAmount,
        maxAmount: currentState.maxAmount,
        expenseCategories: event.categories,
        incomeCategories: currentState.incomeCategories,
        searchQuery: currentState.searchQuery,
        transactionType: currentState.transactionType,
      );

      // Sort and update
      final sortedTransactions = _sortTransactions(
        filteredTransactions,
        currentState.sortField,
        currentState.sortDirection,
      );

      // Update groupings
      final newGroupedData = _updateGroupedData(
        sortedTransactions,
        currentState.groupBy,
      );

      emit(currentState.copyWith(
        filteredTransactions: sortedTransactions,
        expenseCategories: event.categories,
        transactionsByDate: newGroupedData.transactionsByDate,
        transactionsByCategory: newGroupedData.transactionsByCategory,
        amountsByDate: newGroupedData.amountsByDate,
      ));
    }
  }

  /// Handle filtering incomes by category
  void _onFilterIncomesByCategory(
    FilterIncomesByCategory event,
    Emitter<TransactionAnalyticsState> emit,
  ) {
    if (state is TransactionAnalyticsLoaded) {
      final currentState = state as TransactionAnalyticsLoaded;

      // Apply income category filter
      final filteredTransactions = _applyAllFilters(
        expenses: currentState.allExpenses,
        incomes: currentState.allIncomes,
        dateRange: currentState.dateRange,
        minAmount: currentState.minAmount,
        maxAmount: currentState.maxAmount,
        expenseCategories: currentState.expenseCategories,
        incomeCategories: event.categories,
        searchQuery: currentState.searchQuery,
        transactionType: currentState.transactionType,
      );

      // Sort and update
      final sortedTransactions = _sortTransactions(
        filteredTransactions,
        currentState.sortField,
        currentState.sortDirection,
      );

      // Update groupings
      final newGroupedData = _updateGroupedData(
        sortedTransactions,
        currentState.groupBy,
      );

      emit(currentState.copyWith(
        filteredTransactions: sortedTransactions,
        incomeCategories: event.categories,
        transactionsByDate: newGroupedData.transactionsByDate,
        transactionsByCategory: newGroupedData.transactionsByCategory,
        amountsByDate: newGroupedData.amountsByDate,
      ));
    }
  }

  /// Handle text search
  void _onSearchTransactions(
    SearchTransactions event,
    Emitter<TransactionAnalyticsState> emit,
  ) {
    if (state is TransactionAnalyticsLoaded) {
      final currentState = state as TransactionAnalyticsLoaded;

      // Apply search filter
      final filteredTransactions = _applyAllFilters(
        expenses: currentState.allExpenses,
        incomes: currentState.allIncomes,
        dateRange: currentState.dateRange,
        minAmount: currentState.minAmount,
        maxAmount: currentState.maxAmount,
        expenseCategories: currentState.expenseCategories,
        incomeCategories: currentState.incomeCategories,
        searchQuery: event.query,
        transactionType: currentState.transactionType,
      );

      // Sort and update
      final sortedTransactions = _sortTransactions(
        filteredTransactions,
        currentState.sortField,
        currentState.sortDirection,
      );

      // Update groupings
      final newGroupedData = _updateGroupedData(
        sortedTransactions,
        currentState.groupBy,
      );

      emit(currentState.copyWith(
        filteredTransactions: sortedTransactions,
        searchQuery: event.query,
        transactionsByDate: newGroupedData.transactionsByDate,
        transactionsByCategory: newGroupedData.transactionsByCategory,
        amountsByDate: newGroupedData.amountsByDate,
      ));
    }
  }

  /// Handle sorting transactions
  void _onSortTransactions(
    SortTransactions event,
    Emitter<TransactionAnalyticsState> emit,
  ) {
    if (state is TransactionAnalyticsLoaded) {
      final currentState = state as TransactionAnalyticsLoaded;

      // Sort transactions
      final sortedTransactions = _sortTransactions(
        currentState.filteredTransactions,
        event.field,
        event.direction,
      );

      emit(currentState.copyWith(
        filteredTransactions: sortedTransactions,
        sortField: event.field,
        sortDirection: event.direction,
      ));
    }
  }

  /// Handle resetting all filters
  void _onResetFilters(
    ResetFilters event,
    Emitter<TransactionAnalyticsState> emit,
  ) {
    if (state is TransactionAnalyticsLoaded) {
      final currentState = state as TransactionAnalyticsLoaded;

      // Rebuild full list with defaults: no filters, default sort by date desc
      final List<TransactionItem> all = [
        ...currentState.allExpenses.map((e) => TransactionItem.fromExpense(e)),
        ...currentState.allIncomes.map((i) => TransactionItem.fromIncome(i)),
      ]..sort((a, b) => b.date.compareTo(a.date));

      final newGroupedData = _updateGroupedData(all, GroupBy.none);

      emit(currentState.copyWith(
        filteredTransactions: all,
        // clear date and amount filters completely
        setDateRangeNull: true,
        setMinAmountNull: true,
        setMaxAmountNull: true,
        // clear categories and search
        expenseCategories: const [],
        incomeCategories: const [],
        searchQuery: '',
        // default sort
        sortField: SortField.date,
        sortDirection: SortDirection.descending,
        transactionType: TransactionType.all,
        groupBy: GroupBy.none,
        transactionsByDate: newGroupedData.transactionsByDate,
        transactionsByCategory: newGroupedData.transactionsByCategory,
        amountsByDate: newGroupedData.amountsByDate,
      ));
    }
  }

  /// Handle toggling transaction type
  void _onToggleTransactionType(
    ToggleTransactionType event,
    Emitter<TransactionAnalyticsState> emit,
  ) {
    if (state is TransactionAnalyticsLoaded) {
      final currentState = state as TransactionAnalyticsLoaded;
      final newState = currentState.copyWith(
        transactionType: event.type,
      );

      emit(_applyFiltersAndSort(newState));
    }
  }

  /// Handle toggling show all transactions
  void _onToggleShowAllTransactions(
    ToggleShowAllTransactions event,
    Emitter<TransactionAnalyticsState> emit,
  ) {
    if (state is TransactionAnalyticsLoaded) {
      final currentState = state as TransactionAnalyticsLoaded;
      final newState = currentState.copyWith(
        showAllTransactions: !currentState.showAllTransactions,
      );

      emit(newState);
    }
  }

  /// Handle setting the grouping option
  void _onSetGroupingOption(
    SetGroupingOption event,
    Emitter<TransactionAnalyticsState> emit,
  ) {
    if (state is TransactionAnalyticsLoaded) {
      final currentState = state as TransactionAnalyticsLoaded;
      final newState = currentState.copyWith(
        groupBy: event.groupBy,
      );

      emit(_applyFiltersAndSort(newState));
    }
  }

  /// Apply all filters to create a filtered transaction list
  List<TransactionItem> _applyAllFilters({
    required List<Expense> expenses,
    required List<Income> incomes,
    DateTimeRange? dateRange,
    double? minAmount,
    double? maxAmount,
    List<ExpenseCategory>? expenseCategories,
    List<IncomeCategory>? incomeCategories,
    String? searchQuery,
    required TransactionType transactionType,
  }) {
    // Filter expenses based on criteria
    List<Expense> filteredExpenses = expenses;

    // Apply transaction type filter
    if (transactionType == TransactionType.incomes) {
      filteredExpenses = [];
    }

    // Apply date range filter to expenses
    if (dateRange != null) {
      filteredExpenses = filteredExpenses.where((expense) {
        return expense.date.isAfter(dateRange.start) &&
            expense.date.isBefore(dateRange.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Apply amount range filter to expenses
    if (minAmount != null) {
      filteredExpenses = filteredExpenses
          .where((expense) => expense.amount >= minAmount)
          .toList();
    }

    if (maxAmount != null) {
      filteredExpenses = filteredExpenses
          .where((expense) => expense.amount <= maxAmount)
          .toList();
    }

    // Apply expense category filter
    if (expenseCategories != null && expenseCategories.isNotEmpty) {
      filteredExpenses = filteredExpenses
          .where((expense) => expenseCategories.contains(expense.category))
          .toList();
    }

    // Apply search query to expenses
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filteredExpenses = filteredExpenses.where((expense) {
        return expense.title.toLowerCase().contains(query) ||
            (expense.notes?.toLowerCase().contains(query) ?? false) ||
            expense.paymentMethod.toLowerCase().contains(query) ||
            expense.category.displayName.toLowerCase().contains(query);
      }).toList();
    }

    // Filter incomes based on criteria
    List<Income> filteredIncomes = incomes;

    // Apply transaction type filter
    if (transactionType == TransactionType.expenses) {
      filteredIncomes = [];
    }

    // Apply date range filter to incomes
    if (dateRange != null) {
      filteredIncomes = filteredIncomes.where((income) {
        return income.date.isAfter(dateRange.start) &&
            income.date.isBefore(dateRange.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Apply amount range filter to incomes
    if (minAmount != null) {
      filteredIncomes = filteredIncomes
          .where((income) => income.amount >= minAmount)
          .toList();
    }

    if (maxAmount != null) {
      filteredIncomes = filteredIncomes
          .where((income) => income.amount <= maxAmount)
          .toList();
    }

    // Apply income category filter
    if (incomeCategories != null && incomeCategories.isNotEmpty) {
      filteredIncomes = filteredIncomes
          .where((income) => incomeCategories.contains(income.category))
          .toList();
    }

    // Apply search query to incomes
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filteredIncomes = filteredIncomes.where((income) {
        return income.title.toLowerCase().contains(query) ||
            (income.notes?.toLowerCase().contains(query) ?? false) ||
            income.source.toLowerCase().contains(query) ||
            income.category.displayName.toLowerCase().contains(query);
      }).toList();
    }

    // Create unified transaction items
    return [
      ...filteredExpenses.map((e) => TransactionItem.fromExpense(e)),
      ...filteredIncomes.map((i) => TransactionItem.fromIncome(i)),
    ];
  }

  /// Sort transactions based on field and direction
  List<TransactionItem> _sortTransactions(
    List<TransactionItem> transactions,
    SortField field,
    SortDirection direction,
  ) {
    // Return empty list if transactions is empty
    if (transactions.isEmpty) {
      return [];
    }

    final List<TransactionItem> sortedList = List.from(transactions);

    int sortModifier = direction == SortDirection.ascending ? 1 : -1;

    switch (field) {
      case SortField.date:
        sortedList.sort((a, b) => sortModifier * a.date.compareTo(b.date));
        break;
      case SortField.amount:
        sortedList.sort((a, b) => sortModifier * a.amount.compareTo(b.amount));
        break;
      case SortField.category:
        sortedList.sort(
            (a, b) => sortModifier * a.categoryName.compareTo(b.categoryName));
        break;
      case SortField.title:
        sortedList.sort((a, b) => sortModifier * a.title.compareTo(b.title));
        break;
    }

    return sortedList;
  }

  /// Update grouped data based on the grouping option
  _GroupedData _updateGroupedData(
    List<TransactionItem> transactions,
    GroupBy groupBy,
  ) {
    // Group transactions by date (default)
    final Map<DateTime, List<TransactionItem>> transactionsByDate = {};

    // Group transactions by category
    final Map<dynamic, List<TransactionItem>> transactionsByCategory = {};

    // Create amounts by date map
    final Map<DateTime, double> amountsByDate = {};

    // Group by day (default)
    if (groupBy == GroupBy.none || groupBy == GroupBy.day) {
      for (final transaction in transactions) {
        final date = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );

        if (!transactionsByDate.containsKey(date)) {
          transactionsByDate[date] = [];
        }
        transactionsByDate[date]!.add(transaction);

        // Update amounts by date
        if (!amountsByDate.containsKey(date)) {
          amountsByDate[date] = 0;
        }

        if (transaction.isExpense) {
          amountsByDate[date] = amountsByDate[date]! - transaction.amount;
        } else {
          amountsByDate[date] = amountsByDate[date]! + transaction.amount;
        }
      }
    }
    // Group by week
    else if (groupBy == GroupBy.week) {
      for (final transaction in transactions) {
        // Get the first day of the week (Monday)
        final date = transaction.date;
        final weekDay = date.weekday;
        final firstDayOfWeek = date.subtract(Duration(days: weekDay - 1));
        final weekStart = DateTime(
          firstDayOfWeek.year,
          firstDayOfWeek.month,
          firstDayOfWeek.day,
        );

        if (!transactionsByDate.containsKey(weekStart)) {
          transactionsByDate[weekStart] = [];
        }
        transactionsByDate[weekStart]!.add(transaction);

        // Update amounts by date
        if (!amountsByDate.containsKey(weekStart)) {
          amountsByDate[weekStart] = 0;
        }

        if (transaction.isExpense) {
          amountsByDate[weekStart] =
              amountsByDate[weekStart]! - transaction.amount;
        } else {
          amountsByDate[weekStart] =
              amountsByDate[weekStart]! + transaction.amount;
        }
      }
    }
    // Group by month
    else if (groupBy == GroupBy.month) {
      for (final transaction in transactions) {
        // Get the first day of the month
        final monthStart = DateTime(
          transaction.date.year,
          transaction.date.month,
          1,
        );

        if (!transactionsByDate.containsKey(monthStart)) {
          transactionsByDate[monthStart] = [];
        }
        transactionsByDate[monthStart]!.add(transaction);

        // Update amounts by date
        if (!amountsByDate.containsKey(monthStart)) {
          amountsByDate[monthStart] = 0;
        }

        if (transaction.isExpense) {
          amountsByDate[monthStart] =
              amountsByDate[monthStart]! - transaction.amount;
        } else {
          amountsByDate[monthStart] =
              amountsByDate[monthStart]! + transaction.amount;
        }
      }
    }

    // Always group by category regardless of the groupBy option
    for (final transaction in transactions) {
      if (!transactionsByCategory.containsKey(transaction.category)) {
        transactionsByCategory[transaction.category] = [];
      }
      transactionsByCategory[transaction.category]!.add(transaction);
    }

    return _GroupedData(
      transactionsByDate: transactionsByDate,
      transactionsByCategory: transactionsByCategory,
      amountsByDate: amountsByDate,
    );
  }

  /// Apply filters and sort the transactions
  TransactionAnalyticsLoaded _applyFiltersAndSort(
      TransactionAnalyticsLoaded state) {
    // Apply filters
    final filteredTransactions = _applyAllFilters(
      expenses: state.allExpenses,
      incomes: state.allIncomes,
      dateRange: state.dateRange,
      minAmount: state.minAmount,
      maxAmount: state.maxAmount,
      expenseCategories: state.expenseCategories,
      incomeCategories: state.incomeCategories,
      searchQuery: state.searchQuery,
      transactionType: state.transactionType,
    );

    // Sort transactions
    final sortedTransactions = _sortTransactions(
      filteredTransactions,
      state.sortField,
      state.sortDirection,
    );

    // Update groupings
    final newGroupedData = _updateGroupedData(
      sortedTransactions,
      state.groupBy,
    );

    return state.copyWith(
      filteredTransactions: sortedTransactions,
      transactionsByDate: newGroupedData.transactionsByDate,
      transactionsByCategory: newGroupedData.transactionsByCategory,
      amountsByDate: newGroupedData.amountsByDate,
    );
  }
}

/// Helper class for grouped data
class _GroupedData {
  final Map<DateTime, List<TransactionItem>> transactionsByDate;
  final Map<dynamic, List<TransactionItem>> transactionsByCategory;
  final Map<DateTime, double> amountsByDate;

  _GroupedData({
    required this.transactionsByDate,
    required this.transactionsByCategory,
    required this.amountsByDate,
  });
}

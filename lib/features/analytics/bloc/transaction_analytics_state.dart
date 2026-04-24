import 'package:equatable/equatable.dart';
import 'package:finance_track/data/models/expense_model.dart';
import 'package:finance_track/data/models/income_model.dart';
import 'package:finance_track/features/monthly_summary/models/transaction_item.dart';
import 'package:finance_track/features/analytics/bloc/transaction_analytics_event.dart';
import 'package:flutter/material.dart';

/// Base class for all transaction analytics states
abstract class TransactionAnalyticsState extends Equatable {
  const TransactionAnalyticsState();

  @override
  List<Object?> get props => [];
}

/// Initial state of transaction analytics
class TransactionAnalyticsInitial extends TransactionAnalyticsState {
  const TransactionAnalyticsInitial();
}

/// Loading state when fetching transaction data
class TransactionAnalyticsLoading extends TransactionAnalyticsState {
  const TransactionAnalyticsLoading();
}

/// Error state when transaction data fetch fails
class TransactionAnalyticsError extends TransactionAnalyticsState {
  final String message;

  const TransactionAnalyticsError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Transaction data loaded successfully
class TransactionAnalyticsLoaded extends TransactionAnalyticsState {
  // All data sources
  final List<Expense> allExpenses;
  final List<Income> allIncomes;

  // Filtered and processed data for display
  final List<TransactionItem> filteredTransactions;
  final Map<DateTime, List<TransactionItem>> transactionsByDate;
  final Map<dynamic, List<TransactionItem>> transactionsByCategory;
  final Map<String, double> categoryTotals;

  // Filter and sort state
  final DateTimeRange? dateRange;
  final double? minAmount;
  final double? maxAmount;
  final List<ExpenseCategory>? expenseCategories;
  final List<IncomeCategory>? incomeCategories;
  final String? searchQuery;
  final SortField sortField;
  final SortDirection sortDirection;
  final TransactionType transactionType;
  final GroupBy groupBy;

  // Statistics and aggregates
  final double totalExpenses;
  final double totalIncomes;
  final double netBalance;
  final Map<dynamic, double> amountsByCategory;
  final Map<DateTime, double> amountsByDate;

  // UI state
  final bool showAllTransactions;

  const TransactionAnalyticsLoaded({
    required this.allExpenses,
    required this.allIncomes,
    required this.filteredTransactions,
    required this.transactionsByDate,
    required this.transactionsByCategory,
    required this.categoryTotals,
    this.dateRange,
    this.minAmount,
    this.maxAmount,
    this.expenseCategories,
    this.incomeCategories,
    this.searchQuery,
    this.sortField = SortField.date,
    this.sortDirection = SortDirection.descending,
    this.transactionType = TransactionType.all,
    this.groupBy = GroupBy.none,
    required this.totalExpenses,
    required this.totalIncomes,
    required this.netBalance,
    required this.amountsByCategory,
    required this.amountsByDate,
    this.showAllTransactions = false,
  });

  @override
  List<Object?> get props => [
        filteredTransactions,
        dateRange,
        minAmount,
        maxAmount,
        expenseCategories,
        incomeCategories,
        searchQuery,
        sortField,
        sortDirection,
        transactionType,
        groupBy,
        totalExpenses,
        totalIncomes,
        netBalance,
        showAllTransactions,
      ];

  /// Create a copy of this state with updated fields
  TransactionAnalyticsLoaded copyWith({
    List<Expense>? allExpenses,
    List<Income>? allIncomes,
    List<TransactionItem>? filteredTransactions,
    Map<DateTime, List<TransactionItem>>? transactionsByDate,
    Map<dynamic, List<TransactionItem>>? transactionsByCategory,
    Map<String, double>? categoryTotals,
    DateTimeRange? dateRange,
    double? minAmount,
    double? maxAmount,
    List<ExpenseCategory>? expenseCategories,
    List<IncomeCategory>? incomeCategories,
    String? searchQuery,
    SortField? sortField,
    SortDirection? sortDirection,
    TransactionType? transactionType,
    GroupBy? groupBy,
    double? totalExpenses,
    double? totalIncomes,
    double? netBalance,
    Map<dynamic, double>? amountsByCategory,
    Map<DateTime, double>? amountsByDate,
    bool? showAllTransactions,
    // Explicit reset flags for nullable fields
    bool setDateRangeNull = false,
    bool setMinAmountNull = false,
    bool setMaxAmountNull = false,
  }) {
    return TransactionAnalyticsLoaded(
      allExpenses: allExpenses ?? this.allExpenses,
      allIncomes: allIncomes ?? this.allIncomes,
      filteredTransactions: filteredTransactions ?? this.filteredTransactions,
      transactionsByDate: transactionsByDate ?? this.transactionsByDate,
      transactionsByCategory:
          transactionsByCategory ?? this.transactionsByCategory,
      categoryTotals: categoryTotals ?? this.categoryTotals,
      dateRange: setDateRangeNull ? null : (dateRange ?? this.dateRange),
      minAmount: setMinAmountNull ? null : (minAmount ?? this.minAmount),
      maxAmount: setMaxAmountNull ? null : (maxAmount ?? this.maxAmount),
      expenseCategories: expenseCategories ?? this.expenseCategories,
      incomeCategories: incomeCategories ?? this.incomeCategories,
      searchQuery: searchQuery ?? this.searchQuery,
      sortField: sortField ?? this.sortField,
      sortDirection: sortDirection ?? this.sortDirection,
      transactionType: transactionType ?? this.transactionType,
      groupBy: groupBy ?? this.groupBy,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalIncomes: totalIncomes ?? this.totalIncomes,
      netBalance: netBalance ?? this.netBalance,
      amountsByCategory: amountsByCategory ?? this.amountsByCategory,
      amountsByDate: amountsByDate ?? this.amountsByDate,
      showAllTransactions: showAllTransactions ?? this.showAllTransactions,
    );
  }
}

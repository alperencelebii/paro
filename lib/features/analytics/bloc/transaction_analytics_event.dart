import 'package:equatable/equatable.dart';
import 'package:finance_track/data/models/expense_model.dart';
import 'package:finance_track/data/models/income_model.dart';
import 'package:flutter/material.dart';

/// Base class for all transaction analytics events
abstract class TransactionAnalyticsEvent extends Equatable {
  const TransactionAnalyticsEvent();

  @override
  List<Object?> get props => [];
}

/// Load transaction data for analytics
class LoadTransactionAnalytics extends TransactionAnalyticsEvent {
  const LoadTransactionAnalytics();
}

/// Filter transactions by date range
class FilterTransactionsByDateRange extends TransactionAnalyticsEvent {
  final DateTimeRange dateRange;

  const FilterTransactionsByDateRange(this.dateRange);

  @override
  List<Object?> get props => [dateRange];
}

/// Clear date range filter
class ClearDateRangeFilter extends TransactionAnalyticsEvent {
  const ClearDateRangeFilter();
}

/// Filter transactions by amount range
class FilterTransactionsByAmountRange extends TransactionAnalyticsEvent {
  final double minAmount;
  final double maxAmount;

  const FilterTransactionsByAmountRange({
    required this.minAmount,
    required this.maxAmount,
  });

  @override
  List<Object?> get props => [minAmount, maxAmount];
}

/// Clear amount filter
class ClearAmountFilter extends TransactionAnalyticsEvent {
  const ClearAmountFilter();
}

/// Filter expense transactions by category
class FilterExpensesByCategory extends TransactionAnalyticsEvent {
  final List<ExpenseCategory> categories;

  const FilterExpensesByCategory(this.categories);

  @override
  List<Object?> get props => [categories];
}

/// Filter income transactions by category
class FilterIncomesByCategory extends TransactionAnalyticsEvent {
  final List<IncomeCategory> categories;

  const FilterIncomesByCategory(this.categories);

  @override
  List<Object?> get props => [categories];
}

/// Filter transactions by text search query
class SearchTransactions extends TransactionAnalyticsEvent {
  final String query;

  const SearchTransactions(this.query);

  @override
  List<Object?> get props => [query];
}

/// Sort transactions by specified field and direction
class SortTransactions extends TransactionAnalyticsEvent {
  final SortField field;
  final SortDirection direction;

  const SortTransactions({
    required this.field,
    required this.direction,
  });

  @override
  List<Object?> get props => [field, direction];
}

/// Reset all applied filters
class ResetFilters extends TransactionAnalyticsEvent {
  const ResetFilters();
}

/// Toggle between showing expenses, incomes, or both
class ToggleTransactionType extends TransactionAnalyticsEvent {
  final TransactionType type;

  const ToggleTransactionType(this.type);

  @override
  List<Object?> get props => [type];
}

/// Set the group by option
class SetGroupingOption extends TransactionAnalyticsEvent {
  final GroupBy groupBy;

  const SetGroupingOption(this.groupBy);

  @override
  List<Object?> get props => [groupBy];
}

/// Toggle showing all transactions or a limited number
class ToggleShowAllTransactions extends TransactionAnalyticsEvent {
  const ToggleShowAllTransactions();
}

/// Enum for transaction types
enum TransactionType {
  all,
  expenses,
  incomes,
}

/// Enum for sorting fields
enum SortField {
  date,
  amount,
  category,
  title,
}

/// Enum for sort directions
enum SortDirection {
  ascending,
  descending,
}

/// Enum for grouping options
enum GroupBy {
  none,
  day,
  week,
  month,
  category,
}

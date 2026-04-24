part of 'category_analysis_bloc.dart';

abstract class CategoryAnalysisEvent extends Equatable {
  const CategoryAnalysisEvent();

  @override
  List<Object?> get props => [];
}

class LoadCategoryAnalysis extends CategoryAnalysisEvent {
  const LoadCategoryAnalysis();
}

class UpdateTimeFrame extends CategoryAnalysisEvent {
  final int timeFrame;

  const UpdateTimeFrame(this.timeFrame);

  @override
  List<Object?> get props => [timeFrame];
}

class ToggleDataType extends CategoryAnalysisEvent {
  final bool showExpense;
  final bool showIncome;

  const ToggleDataType({
    required this.showExpense,
    required this.showIncome,
  });

  @override
  List<Object?> get props => [showExpense, showIncome];
}

class LoadCategoryDetail extends CategoryAnalysisEvent {
  final dynamic category; // ExpenseCategory or IncomeCategory enum
  final bool isExpense;
  final int timeFrame;
  final DateTimeRange? dateRange;

  const LoadCategoryDetail({
    required this.category,
    required this.isExpense,
    required this.timeFrame,
    this.dateRange,
  });

  @override
  List<Object?> get props => [category, isExpense, timeFrame, dateRange];
}

class FilterCategoryData extends CategoryAnalysisEvent {
  final DateTimeRange? customDateRange;
  final List<dynamic>? selectedCategories;
  final double? minAmount;
  final double? maxAmount;

  const FilterCategoryData({
    this.customDateRange,
    this.selectedCategories,
    this.minAmount,
    this.maxAmount,
  });

  @override
  List<Object?> get props =>
      [customDateRange, selectedCategories, minAmount, maxAmount];
}

class CompareCategoryPeriods extends CategoryAnalysisEvent {
  final DateTimeRange firstPeriod;
  final DateTimeRange secondPeriod;
  final bool isExpense;
  final dynamic category;

  const CompareCategoryPeriods({
    required this.firstPeriod,
    required this.secondPeriod,
    required this.isExpense,
    required this.category,
  });

  @override
  List<Object?> get props => [firstPeriod, secondPeriod, isExpense, category];
}

class CalculatePrediction extends CategoryAnalysisEvent {
  final dynamic category;
  final bool isExpense;
  final int predictionMonths;

  const CalculatePrediction({
    required this.category,
    required this.isExpense,
    this.predictionMonths = 3,
  });

  @override
  List<Object?> get props => [category, isExpense, predictionMonths];
}

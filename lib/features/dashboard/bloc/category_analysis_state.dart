part of 'category_analysis_bloc.dart';

abstract class CategoryAnalysisState extends Equatable {
  const CategoryAnalysisState();

  @override
  List<Object?> get props => [];
}

class CategoryAnalysisInitial extends CategoryAnalysisState {}

class CategoryAnalysisLoading extends CategoryAnalysisState {}

class CategoryAnalysisLoaded extends CategoryAnalysisState {
  final Map<dynamic, double> expenseCategoriesAmount;
  final Map<IncomeCategory, double> incomeCategoriesAmount;
  final Map<dynamic, double> expenseCategoriesPercentage;
  final Map<IncomeCategory, double> incomeCategoriesPercentage;
  final double totalExpenses;
  final double totalIncomes;
  final int timeFrame;
  final bool showExpense;
  final bool showIncome;

  const CategoryAnalysisLoaded({
    required this.expenseCategoriesAmount,
    required this.incomeCategoriesAmount,
    required this.expenseCategoriesPercentage,
    required this.incomeCategoriesPercentage,
    required this.totalExpenses,
    required this.totalIncomes,
    this.timeFrame = 30,
    this.showExpense = true,
    this.showIncome = true,
  });

  @override
  List<Object?> get props => [
        expenseCategoriesAmount,
        incomeCategoriesAmount,
        expenseCategoriesPercentage,
        incomeCategoriesPercentage,
        totalExpenses,
        totalIncomes,
        timeFrame,
        showExpense,
        showIncome,
      ];

  CategoryAnalysisLoaded copyWith({
    Map<dynamic, double>? expenseCategoriesAmount,
    Map<IncomeCategory, double>? incomeCategoriesAmount,
    Map<dynamic, double>? expenseCategoriesPercentage,
    Map<IncomeCategory, double>? incomeCategoriesPercentage,
    double? totalExpenses,
    double? totalIncomes,
    int? timeFrame,
    bool? showExpense,
    bool? showIncome,
  }) {
    return CategoryAnalysisLoaded(
      expenseCategoriesAmount:
          expenseCategoriesAmount ?? this.expenseCategoriesAmount,
      incomeCategoriesAmount:
          incomeCategoriesAmount ?? this.incomeCategoriesAmount,
      expenseCategoriesPercentage:
          expenseCategoriesPercentage ?? this.expenseCategoriesPercentage,
      incomeCategoriesPercentage:
          incomeCategoriesPercentage ?? this.incomeCategoriesPercentage,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalIncomes: totalIncomes ?? this.totalIncomes,
      timeFrame: timeFrame ?? this.timeFrame,
      showExpense: showExpense ?? this.showExpense,
      showIncome: showIncome ?? this.showIncome,
    );
  }
}

// Periodic data structure for charting
class PeriodicData {
  final DateTime date;
  final double amount;

  PeriodicData({required this.date, required this.amount});
}

class CategoryDetailLoaded extends CategoryAnalysisState {
  final dynamic category;
  final bool isExpense;
  final double totalAmount;
  final double averageAmount;
  final int transactionCount;
  final double percentageOfTotal;
  final List<PeriodicData> periodicData;
  final List<TransactionItem> transactions;
  final int timeFrame;
  final DateTimeRange dateRange;

  const CategoryDetailLoaded({
    required this.category,
    required this.isExpense,
    required this.totalAmount,
    required this.averageAmount,
    required this.transactionCount,
    required this.percentageOfTotal,
    required this.periodicData,
    required this.transactions,
    required this.timeFrame,
    required this.dateRange,
  });

  @override
  List<Object?> get props => [
        category,
        isExpense,
        totalAmount,
        averageAmount,
        transactionCount,
        percentageOfTotal,
        periodicData,
        transactions,
        timeFrame,
        dateRange,
      ];
}

class CategoryAnalysisError extends CategoryAnalysisState {
  final String message;

  const CategoryAnalysisError(this.message);

  @override
  List<Object?> get props => [message];
}

class CategoryFilteredData extends CategoryAnalysisState {
  final dynamic category;
  final bool isExpense;
  final List<dynamic> filteredTransactions;
  final double totalFilteredAmount;
  final DateTimeRange? filteredDateRange;
  final double? minAmount;
  final double? maxAmount;

  const CategoryFilteredData({
    required this.category,
    required this.isExpense,
    required this.filteredTransactions,
    required this.totalFilteredAmount,
    this.filteredDateRange,
    this.minAmount,
    this.maxAmount,
  });

  @override
  List<Object?> get props => [
        category,
        isExpense,
        filteredTransactions,
        totalFilteredAmount,
        filteredDateRange,
        minAmount,
        maxAmount,
      ];
}

class CategoryComparisonLoaded extends CategoryAnalysisState {
  final dynamic category;
  final bool isExpense;
  final DateTimeRange firstPeriod;
  final DateTimeRange secondPeriod;
  final double firstPeriodAmount;
  final double secondPeriodAmount;
  final int firstPeriodCount;
  final int secondPeriodCount;
  final double percentageChange;
  final List<PeriodicData> firstPeriodData;
  final List<PeriodicData> secondPeriodData;

  const CategoryComparisonLoaded({
    required this.category,
    required this.isExpense,
    required this.firstPeriod,
    required this.secondPeriod,
    required this.firstPeriodAmount,
    required this.secondPeriodAmount,
    required this.firstPeriodCount,
    required this.secondPeriodCount,
    required this.percentageChange,
    required this.firstPeriodData,
    required this.secondPeriodData,
  });

  @override
  List<Object?> get props => [
        category,
        isExpense,
        firstPeriod,
        secondPeriod,
        firstPeriodAmount,
        secondPeriodAmount,
        firstPeriodCount,
        secondPeriodCount,
        percentageChange,
        firstPeriodData,
        secondPeriodData,
      ];
}

class CategoryPredictionLoaded extends CategoryAnalysisState {
  final dynamic category;
  final bool isExpense;
  final List<PeriodicData> historicalData;
  final List<PeriodicData> predictedData;
  final double projectedTotal;
  final double projectedAverage;
  final double growthRate;
  final String trendDescription;

  const CategoryPredictionLoaded({
    required this.category,
    required this.isExpense,
    required this.historicalData,
    required this.predictedData,
    required this.projectedTotal,
    required this.projectedAverage,
    required this.growthRate,
    required this.trendDescription,
  });

  @override
  List<Object?> get props => [
        category,
        isExpense,
        historicalData,
        predictedData,
        projectedTotal,
        projectedAverage,
        growthRate,
        trendDescription,
      ];
}

class CategoryPeriodComparisonLoaded extends CategoryAnalysisState {
  final dynamic category;
  final bool isExpense;
  final DateTimeRange firstPeriod;
  final DateTimeRange secondPeriod;
  final double firstPeriodTotal;
  final double secondPeriodTotal;
  final double percentageChange;
  final int firstPeriodTransactionCount;
  final int secondPeriodTransactionCount;
  final double firstPeriodAverage;
  final double secondPeriodAverage;
  final List<PeriodicData> firstPeriodData;
  final List<PeriodicData> secondPeriodData;

  const CategoryPeriodComparisonLoaded({
    required this.category,
    required this.isExpense,
    required this.firstPeriod,
    required this.secondPeriod,
    required this.firstPeriodTotal,
    required this.secondPeriodTotal,
    required this.percentageChange,
    required this.firstPeriodTransactionCount,
    required this.secondPeriodTransactionCount,
    required this.firstPeriodAverage,
    required this.secondPeriodAverage,
    required this.firstPeriodData,
    required this.secondPeriodData,
  });

  @override
  List<Object?> get props => [
        category,
        isExpense,
        firstPeriod,
        secondPeriod,
        firstPeriodTotal,
        secondPeriodTotal,
        percentageChange,
        firstPeriodTransactionCount,
        secondPeriodTransactionCount,
        firstPeriodAverage,
        secondPeriodAverage,
        firstPeriodData,
        secondPeriodData,
      ];
}

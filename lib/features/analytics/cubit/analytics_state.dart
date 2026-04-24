import 'package:equatable/equatable.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/income_model.dart';

enum TimeFrame { day, week, month }

extension TimeFrameX on TimeFrame {
  String get displayName {
    switch (this) {
      case TimeFrame.day:
        return 'Day';
      case TimeFrame.week:
        return 'Week';
      case TimeFrame.month:
        return 'Month';
    }
  }
}

class DailyExpense {
  final DateTime date;
  final double amount;
  final double percentage;

  DailyExpense({
    required this.date,
    required this.amount,
    required this.percentage,
  });
}

class DailyIncome {
  final DateTime date;
  final double amount;
  final double percentage;

  DailyIncome({
    required this.date,
    required this.amount,
    required this.percentage,
  });
}

class CategoryExpense {
  final ExpenseCategory category;
  final double amount;
  final double percentage;

  CategoryExpense({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

class CategoryIncome {
  final IncomeCategory category;
  final double amount;
  final double percentage;

  CategoryIncome({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

abstract class AnalyticsState extends Equatable {
  const AnalyticsState();

  @override
  List<Object?> get props => [];
}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {}

class AnalyticsLoaded extends AnalyticsState {
  final double totalExpenses;
  final double totalIncomes;
  final List<Expense> allExpenses;
  final List<Income> allIncomes;
  final TimeFrame selectedTimeFrame;
  final List<DailyExpense> dailyExpenses;
  final List<DailyIncome> dailyIncomes;
  final List<CategoryExpense> categoryExpenses;
  final List<CategoryIncome> categoryIncomes;
  final DateTime selectedMonth;

  const AnalyticsLoaded({
    required this.totalExpenses,
    required this.totalIncomes,
    required this.allExpenses,
    required this.allIncomes,
    required this.selectedTimeFrame,
    required this.dailyExpenses,
    required this.dailyIncomes,
    required this.categoryExpenses,
    required this.categoryIncomes,
    required this.selectedMonth,
  });

  @override
  List<Object?> get props => [
        totalExpenses,
        totalIncomes,
        allExpenses,
        allIncomes,
        selectedTimeFrame,
        dailyExpenses,
        dailyIncomes,
        categoryExpenses,
        categoryIncomes,
        selectedMonth,
      ];

  double get netBalance => totalIncomes - totalExpenses;

  double getTimeFrameExpenseTotal() {
    switch (selectedTimeFrame) {
      case TimeFrame.day:
        return dailyExpenses.isEmpty ? 0 : dailyExpenses.first.amount;
      case TimeFrame.week:
        return dailyExpenses
            .where((expense) => expense.date
                .isAfter(DateTime.now().subtract(const Duration(days: 7))))
            .fold(0, (sum, expense) => sum + expense.amount);
      case TimeFrame.month:
        return dailyExpenses.fold(0, (sum, expense) => sum + expense.amount);
    }
  }

  double getTimeFrameIncomeTotal() {
    switch (selectedTimeFrame) {
      case TimeFrame.day:
        return dailyIncomes.isEmpty ? 0 : dailyIncomes.first.amount;
      case TimeFrame.week:
        return dailyIncomes
            .where((income) => income.date
                .isAfter(DateTime.now().subtract(const Duration(days: 7))))
            .fold(0, (sum, income) => sum + income.amount);
      case TimeFrame.month:
        return dailyIncomes.fold(0, (sum, income) => sum + income.amount);
    }
  }

  double getTimeFrameNetBalance() {
    return getTimeFrameIncomeTotal() - getTimeFrameExpenseTotal();
  }

  AnalyticsLoaded copyWith({
    double? totalExpenses,
    double? totalIncomes,
    List<Expense>? allExpenses,
    List<Income>? allIncomes,
    TimeFrame? selectedTimeFrame,
    List<DailyExpense>? dailyExpenses,
    List<DailyIncome>? dailyIncomes,
    List<CategoryExpense>? categoryExpenses,
    List<CategoryIncome>? categoryIncomes,
    DateTime? selectedMonth,
  }) {
    return AnalyticsLoaded(
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalIncomes: totalIncomes ?? this.totalIncomes,
      allExpenses: allExpenses ?? this.allExpenses,
      allIncomes: allIncomes ?? this.allIncomes,
      selectedTimeFrame: selectedTimeFrame ?? this.selectedTimeFrame,
      dailyExpenses: dailyExpenses ?? this.dailyExpenses,
      dailyIncomes: dailyIncomes ?? this.dailyIncomes,
      categoryExpenses: categoryExpenses ?? this.categoryExpenses,
      categoryIncomes: categoryIncomes ?? this.categoryIncomes,
      selectedMonth: selectedMonth ?? this.selectedMonth,
    );
  }
}

class AnalyticsError extends AnalyticsState {
  final String message;

  const AnalyticsError(this.message);

  @override
  List<Object> get props => [message];
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../data/repositories/income_repository.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/income_model.dart';

/// State for date-wise expense
sealed class DateWiseExpenseState extends Equatable {
  const DateWiseExpenseState();

  @override
  List<Object?> get props => [];
}

class DateWiseExpenseInitial extends DateWiseExpenseState {
  const DateWiseExpenseInitial();
}

class DateWiseExpenseLoading extends DateWiseExpenseState {
  const DateWiseExpenseLoading();
}

class DateWiseExpenseLoaded extends DateWiseExpenseState {
  final List<DailyExpenseData> dailyData;
  final double totalExpense;
  final double totalIncome;
  final double changePercentage;
  final List<Expense> allExpenses;
  final List<Income> allIncomes;

  const DateWiseExpenseLoaded({
    required this.dailyData,
    required this.totalExpense,
    required this.totalIncome,
    required this.changePercentage,
    required this.allExpenses,
    required this.allIncomes,
  });

  @override
  List<Object?> get props => [
        dailyData,
        totalExpense,
        totalIncome,
        changePercentage,
        allExpenses,
        allIncomes
      ];

  /// Get transactions for a specific date
  List<dynamic> getTransactionsForDate(DateTime date) {
    final selectedDate = DateTime(date.year, date.month, date.day);
    final List<dynamic> transactions = [];

    // Add expenses for the date
    for (final expense in allExpenses) {
      final expenseDate = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      if (expenseDate.isAtSameMomentAs(selectedDate)) {
        transactions.add(expense);
      }
    }

    // Add incomes for the date
    for (final income in allIncomes) {
      final incomeDate = DateTime(
        income.date.year,
        income.date.month,
        income.date.day,
      );
      if (incomeDate.isAtSameMomentAs(selectedDate)) {
        transactions.add(income);
      }
    }

    // Sort by date/time (newest first)
    transactions.sort((a, b) {
      final dateA = a is Expense ? a.date : (a as Income).date;
      final dateB = b is Expense ? b.date : (b as Income).date;
      return dateB.compareTo(dateA);
    });

    return transactions;
  }
}

class DateWiseExpenseError extends DateWiseExpenseState {
  final String message;

  const DateWiseExpenseError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Data model for daily expense/income summary
class DailyExpenseData {
  final DateTime date;
  final double expense;
  final double income;

  const DailyExpenseData({
    required this.date,
    required this.expense,
    required this.income,
  });

  double get total => expense + income;
}

/// Cubit for managing date-wise expense data
class DateWiseExpenseCubit extends Cubit<DateWiseExpenseState> {
  final ExpenseRepository _expenseRepository;
  final IncomeRepository _incomeRepository;

  DateWiseExpenseCubit({
    required ExpenseRepository expenseRepository,
    required IncomeRepository incomeRepository,
  })  : _expenseRepository = expenseRepository,
        _incomeRepository = incomeRepository,
        super(const DateWiseExpenseInitial());

  /// Load last N days of expense/income data
  Future<void> loadDateWiseData({int days = 10}) async {
    emit(const DateWiseExpenseLoading());

    try {
      final expenses = await _expenseRepository.getAllExpenses();
      final incomes = await _incomeRepository.getAllIncomes();

      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days - 1));

      // Create a map of date to expense/income totals
      final dailyDataMap = <DateTime, DailyExpenseData>{};

      // Initialize all dates with zero values
      for (int i = 0; i < days; i++) {
        final date = startDate.add(Duration(days: i));
        final dateOnly = DateTime(date.year, date.month, date.day);
        dailyDataMap[dateOnly] = DailyExpenseData(
          date: dateOnly,
          expense: 0.0,
          income: 0.0,
        );
      }

      // Calculate expenses by date
      for (final expense in expenses) {
        final expenseDate = DateTime(
          expense.date.year,
          expense.date.month,
          expense.date.day,
        );
        final existing = dailyDataMap[expenseDate];
        if (existing != null) {
          dailyDataMap[expenseDate] = DailyExpenseData(
            date: expenseDate,
            expense: existing.expense + expense.amount,
            income: existing.income,
          );
        }
      }

      // Calculate incomes by date
      for (final income in incomes) {
        final incomeDate = DateTime(
          income.date.year,
          income.date.month,
          income.date.day,
        );
        final existing = dailyDataMap[incomeDate];
        if (existing != null) {
          dailyDataMap[incomeDate] = DailyExpenseData(
            date: incomeDate,
            expense: existing.expense,
            income: existing.income + income.amount,
          );
        }
      }

      // Convert to list and sort by date
      final dailyData = dailyDataMap.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      // Calculate totals
      final totalExpense = dailyData.fold<double>(
        0.0,
        (sum, data) => sum + data.expense,
      );
      final totalIncome = dailyData.fold<double>(
        0.0,
        (sum, data) => sum + data.income,
      );

      // Calculate change percentage (compare first half vs second half)
      double changePercentage = 0.0;
      if (dailyData.length > 1) {
        final midPoint = dailyData.length ~/ 2;
        final firstHalfTotal = dailyData
            .sublist(0, midPoint)
            .fold<double>(0.0, (sum, data) => sum + data.expense);
        final secondHalfTotal = dailyData
            .sublist(midPoint)
            .fold<double>(0.0, (sum, data) => sum + data.expense);

        if (firstHalfTotal > 0) {
          changePercentage =
              ((secondHalfTotal - firstHalfTotal) / firstHalfTotal) * 100;
        } else if (secondHalfTotal > 0) {
          changePercentage = 100.0;
        }
      }

      emit(DateWiseExpenseLoaded(
        dailyData: dailyData,
        totalExpense: totalExpense,
        totalIncome: totalIncome,
        changePercentage: changePercentage,
        allExpenses: expenses,
        allIncomes: incomes,
      ));
    } catch (e) {
      emit(DateWiseExpenseError(message: e.toString()));
    }
  }
}

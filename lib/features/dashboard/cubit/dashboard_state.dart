import 'package:equatable/equatable.dart';

import '../../../data/models/expense_model.dart';
import '../../../data/models/income_model.dart';

/// Dashboard state
sealed class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

/// Loading state
class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

/// Error state
class DashboardError extends DashboardState {
  final String message;

  const DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Loaded state with all dashboard data
class DashboardLoaded extends DashboardState {
  final double balance;
  final double totalIncomes;
  final double totalExpenses;
  final double thisMonthIncomes;
  final double thisMonthExpenses;
  final double thisMonthBalance;
  final double incomeChange;
  final double expenseChange;
  final List<dynamic> recentTransactions;
  final Map<ExpenseCategory, double> expenseByCategory;
  final Map<IncomeCategory, double> incomeByCategory;
  final List<Expense> expenses;
  final Map<ExpenseCategory, double> topExpenseCategories;
  final Map<IncomeCategory, double> topIncomeCategories;

  const DashboardLoaded({
    required this.balance,
    required this.totalIncomes,
    required this.totalExpenses,
    required this.thisMonthIncomes,
    required this.thisMonthExpenses,
    required this.thisMonthBalance,
    required this.incomeChange,
    required this.expenseChange,
    required this.recentTransactions,
    required this.expenseByCategory,
    required this.incomeByCategory,
    required this.expenses,
    required this.topExpenseCategories,
    required this.topIncomeCategories,
  });

  @override
  List<Object?> get props => [
        balance,
        totalIncomes,
        totalExpenses,
        thisMonthIncomes,
        thisMonthExpenses,
        thisMonthBalance,
        incomeChange,
        expenseChange,
        recentTransactions,
        expenseByCategory,
        incomeByCategory,
        expenses,
        topExpenseCategories,
        topIncomeCategories,
      ];
}

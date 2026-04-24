import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/expense_model.dart';
import '../../../data/models/income_model.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../data/repositories/income_repository.dart';
import '../../budget/bloc/budget_bloc/budget_bloc.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final ExpenseRepository _expenseRepository;
  final IncomeRepository _incomeRepository;
  final BudgetBloc? _budgetBloc;

  // Set this to false to disable dashboard loading logs
  static const bool enableDebugLogs = false;

  DashboardCubit({
    required ExpenseRepository expenseRepository,
    required IncomeRepository incomeRepository,
    BudgetBloc? budgetBloc,
  })  : _expenseRepository = expenseRepository,
        _incomeRepository = incomeRepository,
        _budgetBloc = budgetBloc,
        super(const DashboardInitial());

  Future<void> loadDashboardData() async {
    emit(const DashboardLoading());

    try {
      final expenses = await _expenseRepository.getAllExpenses();
      final incomes = await _incomeRepository.getAllIncomes();

      final thisMonthExpenses = _filterCurrentMonthItems(expenses);
      final thisMonthIncomes = _filterCurrentMonthItems(incomes);

      final lastMonthExpenses = _filterLastMonthItems(expenses);
      final lastMonthIncomes = _filterLastMonthItems(incomes);

      // Calculate totals
      final totalExpenses = _calculateTotal(expenses);
      final totalIncomes = _calculateTotal(incomes);
      final balance = totalIncomes - totalExpenses;

      // Calculate this month totals
      final thisMonthExpensesTotal = _calculateTotal(thisMonthExpenses);
      final thisMonthIncomesTotal = _calculateTotal(thisMonthIncomes);
      final thisMonthBalance = thisMonthIncomesTotal - thisMonthExpensesTotal;

      // Calculate month-to-month changes
      final lastMonthExpensesTotal = _calculateTotal(lastMonthExpenses);
      final lastMonthIncomesTotal = _calculateTotal(lastMonthIncomes);

      double expenseChange = 0;
      double incomeChange = 0;

      if (lastMonthExpensesTotal > 0) {
        expenseChange = (thisMonthExpensesTotal - lastMonthExpensesTotal) /
            lastMonthExpensesTotal *
            100;
      }

      if (lastMonthIncomesTotal > 0) {
        incomeChange = (thisMonthIncomesTotal - lastMonthIncomesTotal) /
            lastMonthIncomesTotal *
            100;
      }

      // Recent transactions (combined and sorted)
      final recentTransactions = _getRecentTransactions(expenses, incomes);

      // Category analysis
      final expenseByCategory = _analyzeExpenseCategories(expenses);
      final incomeByCategory = _analyzeIncomeCategories(incomes);

      // Get top categories from this month's data
      final thisMonthExpenseByCat =
          _analyzeExpenseCategories(thisMonthExpenses);
      final thisMonthIncomeByCat = _analyzeIncomeCategories(thisMonthIncomes);
      final topExpenseCategories = _getTopCategories(thisMonthExpenseByCat);
      final topIncomeCategories = _getTopCategories(thisMonthIncomeByCat);

      emit(DashboardLoaded(
        balance: balance,
        totalExpenses: totalExpenses,
        totalIncomes: totalIncomes,
        thisMonthExpenses: thisMonthExpensesTotal,
        thisMonthIncomes: thisMonthIncomesTotal,
        thisMonthBalance: thisMonthBalance,
        expenseChange: expenseChange,
        incomeChange: incomeChange,
        recentTransactions: recentTransactions,
        expenseByCategory: expenseByCategory,
        incomeByCategory: incomeByCategory,
        expenses: expenses,
        topExpenseCategories: topExpenseCategories,
        topIncomeCategories: topIncomeCategories,
      ));

      // Update budget stats with the new expenses
      _updateBudgetStats(expenses);
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }

  void _updateBudgetStats(List<Expense> expenses) {
    if (_budgetBloc != null) {
      _budgetBloc!.add(CalculateBudgetStats(expenses));
    }
  }

  // Filter items for the current month
  List<T> _filterCurrentMonthItems<T>(List<T> items) {
    final now = DateTime.now();
    final currentMonth =
        DateTime(now.year, now.month, 1); // First day of current month
    final nextMonth =
        DateTime(now.year, now.month + 1, 1); // First day of next month
    // final currentMonth =
    //     DateTime(now.year, now.month, 1); // First day of current month
    // final nextMonth =
    //     DateTime(now.year, now.month + 1, 1); // First day of next month

    return items.where((item) {
      final date =
          item is Expense ? item.date : (item is Income ? item.date : null);

      if (date == null) return false;

      // Include items exactly on the first day of the month
      return (date.isAtSameMomentAs(currentMonth) ||
              date.isAfter(currentMonth)) &&
          // Include items exactly on the first day of the month
          (date.isAtSameMomentAs(currentMonth) || date.isAfter(currentMonth)) &&
          date.isBefore(nextMonth);
    }).toList();
  }

  // Filter items for the last month
  List<T> _filterLastMonthItems<T>(List<T> items) {
    final now = DateTime.now();
    final lastMonth =
        DateTime(now.year, now.month - 1, 1); // First day of last month
    final currentMonth =
        DateTime(now.year, now.month, 1); // First day of current month
    // final lastMonth =
    //     DateTime(now.year, now.month - 1, 1); // First day of last month
    // final currentMonth =
    //     DateTime(now.year, now.month, 1); // First day of current month

    return items.where((item) {
      final date =
          item is Expense ? item.date : (item is Income ? item.date : null);

      if (date == null) return false;

      // Include items exactly on the first day of the last month
      return (date.isAtSameMomentAs(lastMonth) || date.isAfter(lastMonth)) &&
          // Include items exactly on the first day of the last month
          (date.isAtSameMomentAs(lastMonth) || date.isAfter(lastMonth)) &&
          date.isBefore(currentMonth);
    }).toList();
  }

  // Calculate total amount from list of expenses or incomes
  double _calculateTotal<T>(List<T> items) {
    return items.fold<double>(0, (sum, item) {
      final amount =
          item is Expense ? item.amount : (item is Income ? item.amount : 0);

      return sum + amount;
    });
  }

  // Get recent transactions (combined incomes and expenses, sorted by date)
  List<dynamic> _getRecentTransactions(
      List<Expense> expenses, List<Income> incomes) {
    final allTransactions = [...expenses, ...incomes];

    // Sort by date descending (newest first)
    allTransactions.sort((a, b) {
      final dateA =
          a is Expense ? a.date : (a is Income ? a.date : DateTime.now());
      final dateB =
          b is Expense ? b.date : (b is Income ? b.date : DateTime.now());
      return dateB.compareTo(dateA);
    });

    // Take the most recent 10 transactions
    return allTransactions.take(10).toList();
  }

  // Analyze expenses by category
  Map<ExpenseCategory, double> _analyzeExpenseCategories(
      List<Expense> expenses) {
    final result = <ExpenseCategory, double>{};

    // Initialize all categories with zero amount
    for (final category in ExpenseCategory.values) {
      result[category] = 0;
    }

    // Sum up expenses by category
    for (final expense in expenses) {
      result[expense.category] =
          (result[expense.category] ?? 0) + expense.amount;
    }

    return result;
  }

  // Analyze incomes by category
  Map<IncomeCategory, double> _analyzeIncomeCategories(List<Income> incomes) {
    final result = <IncomeCategory, double>{};

    // Initialize all categories with zero amount
    for (final category in IncomeCategory.values) {
      result[category] = 0;
    }

    // Sum up incomes by category
    for (final income in incomes) {
      result[income.category] = (result[income.category] ?? 0) + income.amount;
    }

    return result;
  }

  // Get top categories by amount (returns top 3 categories)
  Map<T, double> _getTopCategories<T>(Map<T, double> categoryMap) {
    // Sort entries by amount in descending order
    final sortedEntries = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 3 categories with non-zero amounts
    final topEntries =
        sortedEntries.where((entry) => entry.value > 0).take(3).toList();

    // Convert back to map
    return Map.fromEntries(topEntries);
  }
}

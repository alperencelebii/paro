import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../core/models/currency_model.dart';
import 'advanced_trend_chart.dart';

/// Example widget demonstrating how to use AdvancedTrendChart
class AdvancedTrendExamples extends StatelessWidget {
  const AdvancedTrendExamples({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Create a sample currency model for demonstration
    const currency = Currency(
      name: 'USD',
      symbol: '\$',
      code: 'USD',
      flag: '',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Trend Examples'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Finance Visualization Examples',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Example 1: Monthly Expenses
            _buildMonthlyExpensesExample(currency),
            const SizedBox(height: 24),

            // Example 2: Income vs Expenses
            _buildIncomeVsExpensesExample(currency),
            const SizedBox(height: 24),

            // Example 3: Category Spending Trend
            _buildCategorySpendingTrendExample(currency),
            const SizedBox(height: 24),

            // Example 4: Budget Planning
            _buildBudgetPlanningExample(currency),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyExpensesExample(Currency currency) {
    // Generate daily expense data for the month
    final List<FlSpot> dailyExpenses = [];
    final List<FlSpot> movingAverage = [];

    // Simulate daily expense data with some fluctuation
    for (int day = 1; day <= 30; day++) {
      double baseAmount = 50.0; // Base daily expense

      // Add weekly patterns (higher on weekends)
      if (day % 7 == 0 || day % 7 == 6) {
        baseAmount *= 1.8;
      }

      // Add some randomness
      final random = day.hashCode % 100 / 100;
      final amount = baseAmount * (0.8 + random * 0.7);

      dailyExpenses.add(FlSpot(day.toDouble(), amount));
    }

    // Calculate 7-day moving average
    for (int day = 7; day <= 30; day++) {
      double sum = 0;
      for (int i = day - 7; i < day; i++) {
        sum += dailyExpenses[i].y;
      }
      final avg = sum / 7;
      movingAverage.add(FlSpot(day.toDouble(), avg));
    }

    // Create legend items
    final legendItems = [
      const LegendItem(
        label: 'Daily Expenses',
        color: Colors.blue,
      ),
      const LegendItem(
        label: '7-Day Average',
        color: Colors.orange,
      ),
    ];

    // Create tooltip formatters
    String primaryTooltipFormatter(double x, double y) {
      final day = x.toInt();
      return 'Day $day: ${NumberFormat.currency(symbol: currency.symbol).format(y)}';
    }

    String secondaryTooltipFormatter(double x, double y) {
      return 'Avg: ${NumberFormat.currency(symbol: currency.symbol).format(y)}';
    }

    return AdvancedTrendChart(
      title: 'Daily Expenses (30-Day View)',
      primaryData: dailyExpenses,
      tertiaryData: movingAverage, // Use tertiary for the average line
      currency: currency,
      height: 300,
      legendItems: legendItems,
      horizontalInterval: 100, // Show grid lines every 100 units
      primaryTooltipFormatter: primaryTooltipFormatter,
      tertiaryTooltipFormatter: secondaryTooltipFormatter,
    );
  }

  Widget _buildIncomeVsExpensesExample(Currency currency) {
    // Generate monthly data for the last 12 months
    final List<FlSpot> expenseData = [];
    final List<FlSpot> incomeData = [];
    final List<String> monthLabels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    // Simulate income and expense data with seasonal patterns
    for (int month = 0; month < 12; month++) {
      // Base income with slight upward trend
      double baseIncome = 3000 + (month * 50);

      // Add seasonal bonus in December
      if (month == 11) baseIncome += 1000;

      // Base expense that follows income pattern but with more variability
      double baseExpense = baseIncome * 0.7;

      // Higher expenses during summer months and December
      if (month >= 5 && month <= 7) baseExpense *= 1.2;
      if (month == 11) baseExpense *= 1.4;

      // Add some randomness
      final randomIncome = month.hashCode % 100 / 100;
      final randomExpense = (month * 2).hashCode % 100 / 100;

      final income = baseIncome * (0.95 + randomIncome * 0.1);
      final expense = baseExpense * (0.9 + randomExpense * 0.3);

      incomeData.add(FlSpot(month.toDouble(), income));
      expenseData.add(FlSpot(month.toDouble(), expense));
    }

    // Create legend items
    final legendItems = [
      const LegendItem(
        label: 'Expenses',
        color: Colors.blue,
      ),
      const LegendItem(
        label: 'Income',
        color: Colors.green,
      ),
    ];

    return AdvancedTrendChart(
      title: 'Income vs Expenses (Last 12 Months)',
      primaryData: expenseData,
      secondaryData: incomeData,
      currency: currency,
      xLabels: monthLabels,
      height: 300,
      legendItems: legendItems,
      horizontalInterval: 1000, // Show grid lines every 1000 units
    );
  }

  Widget _buildCategorySpendingTrendExample(Currency currency) {
    // Generate monthly spending data for a specific category
    final List<FlSpot> foodData = [];
    final List<FlSpot> entertainmentData = [];
    final List<FlSpot> transportData = [];
    final List<String> monthLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];

    // Simulate category spending with different patterns
    for (int month = 0; month < 6; month++) {
      // Food expenses - relatively stable with slight inflation
      double foodBase = 500 + (month * 10);

      // Entertainment - more variable, higher in summer
      double entertainmentBase = 200;
      if (month >= 3) entertainmentBase = 350; // Summer months

      // Transport - stable with a spike in March (vacation)
      double transportBase = 150;
      if (month == 2) transportBase = 400; // March vacation

      // Add randomness
      final random1 = month.hashCode % 100 / 100;
      final random2 = (month * 3).hashCode % 100 / 100;
      final random3 = (month * 7).hashCode % 100 / 100;

      final food = foodBase * (0.9 + random1 * 0.2);
      final entertainment = entertainmentBase * (0.8 + random2 * 0.4);
      final transport = transportBase * (0.9 + random3 * 0.2);

      foodData.add(FlSpot(month.toDouble(), food));
      entertainmentData.add(FlSpot(month.toDouble(), entertainment));
      transportData.add(FlSpot(month.toDouble(), transport));
    }

    // Create legend items
    final legendItems = [
      const LegendItem(
        label: 'Food & Groceries',
        color: Colors.blue,
      ),
      const LegendItem(
        label: 'Entertainment',
        color: Colors.green,
      ),
      const LegendItem(
        label: 'Transport',
        color: Colors.orange,
      ),
    ];

    return AdvancedTrendChart(
      title: 'Category Spending (Last 6 Months)',
      primaryData: foodData,
      secondaryData: entertainmentData,
      tertiaryData: transportData,
      currency: currency,
      xLabels: monthLabels,
      height: 300,
      legendItems: legendItems,
      horizontalInterval: 100, // Show grid lines every 100 units
    );
  }

  Widget _buildBudgetPlanningExample(Currency currency) {
    // Generate spending data and budget plan for comparison
    final List<FlSpot> actualSpending = [];
    final List<FlSpot> budgetPlan = [];
    final List<FlSpot> projectedSpending = [];
    final List<String> monthLabels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    // Budget is planned for the year
    const double monthlyBudget = 2500;

    // We have actual data for first 8 months, and projection for the rest
    for (int month = 0; month < 12; month++) {
      // Budget plan is constant
      budgetPlan.add(FlSpot(month.toDouble(), monthlyBudget));

      if (month < 8) {
        // Actual spending for first 8 months
        double base = monthlyBudget * (0.9 + (month.hashCode % 20) / 100);

        // Summer months tend to exceed budget
        if (month >= 5 && month <= 7) {
          base *= 1.1;
        }

        actualSpending.add(FlSpot(month.toDouble(), base));
      } else {
        // Projection for the rest of the year
        final previousMonth = actualSpending.last.y;
        double projectedBase;

        // December usually has higher spending
        if (month == 11) {
          projectedBase = previousMonth * 1.2;
        } else {
          // Project based on last 3 months trend
          double sum = 0;
          for (int i = month - 3; i < month; i++) {
            if (i < 8) {
              sum += actualSpending[i].y;
            } else {
              sum += projectedSpending[i - 8].y;
            }
          }
          projectedBase = sum / 3;
        }

        projectedSpending.add(FlSpot(month.toDouble(), projectedBase));
      }
    }

    // Create legend items
    final legendItems = [
      const LegendItem(
        label: 'Actual Spending',
        color: Colors.blue,
      ),
      const LegendItem(
        label: 'Budget Plan',
        color: Colors.green,
      ),
      const LegendItem(
        label: 'Projected Spending',
        color: Colors.orange,
      ),
    ];

    return AdvancedTrendChart(
      title: 'Budget Planning & Projection',
      primaryData: actualSpending,
      secondaryData: budgetPlan,
      tertiaryData: projectedSpending,
      currency: currency,
      xLabels: monthLabels,
      height: 300,
      legendItems: legendItems,
      horizontalInterval: 500, // Show grid lines every 500 units
    );
  }
}

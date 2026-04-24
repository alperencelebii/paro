import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

import '../../../core/models/currency_model.dart';

/// Base dashboard card widget that defines common styling for all cards
class DashboardCard extends StatelessWidget {
  final Widget child;
  final String title;
  final Widget? trailing;
  final Color? backgroundColor;
  final double height;
  final EdgeInsetsGeometry? padding;

  const DashboardCard({
    super.key,
    required this.child,
    required this.title,
    this.trailing,
    this.backgroundColor,
    this.height = 150.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp,
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),

            Divider(
                height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),

            // Card Content
            Expanded(
              child: Padding(
                padding: padding ?? EdgeInsets.all(16.r),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header card displaying month and year with status
class MonthHeaderCard extends StatelessWidget {
  final String month;
  final String year;
  final double balance;

  const MonthHeaderCard({
    super.key,
    required this.month,
    required this.year,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isSurplus = balance >= 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$month Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                year,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSurplus ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isSurplus ? Colors.greenAccent : Colors.redAccent,
                  size: 16.r,
                ),
                SizedBox(width: 6.w),
                Text(
                  isSurplus ? 'Surplus' : 'Deficit',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card showing balance information
class BalanceCard extends StatelessWidget {
  final double balance;
  final Currency currency;
  final double? previousMonthBalance;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.currency,
    this.previousMonthBalance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: 2,
    );

    final bool hasComparison = previousMonthBalance != null;
    final bool isPositiveChange =
        hasComparison && previousMonthBalance! < balance;

    // Calculate percentage change
    double percentChange = 0;
    if (hasComparison && previousMonthBalance != 0) {
      percentChange =
          ((balance - previousMonthBalance!) / previousMonthBalance!.abs()) *
              100;
    }

    return Card(
      elevation: 2,
      shadowColor: theme.shadowColor.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Current Balance',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
              ),
            ),

            SizedBox(height: 16.h),

            // Balance row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount with icon
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: balance >= 0
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet,
                          color:
                              balance >= 0 ? Colors.green.shade700 : Colors.red,
                          size: 20.r,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                formatter.format(balance),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: balance >= 0
                                      ? Colors.green.shade700
                                      : Colors.red,
                                ),
                              ),
                            ),
                            if (hasComparison)
                              Text(
                                'vs ${formatter.format(previousMonthBalance!)} last month',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                  fontSize: 12.sp,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Change indicator
                if (hasComparison)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: isPositiveChange
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositiveChange
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: isPositiveChange ? Colors.green : Colors.red,
                          size: 14.r,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          '${percentChange.abs().toStringAsFixed(1)}%',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isPositiveChange ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            SizedBox(height: 16.h),

            // Month comparison bar
            if (hasComparison) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Last Month',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    'This Month',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: SizedBox(
                  height: 8.h,
                  child: LinearProgressIndicator(
                    value: _calculateProgressValue(),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isPositiveChange ? Colors.green : Colors.red,
                    ),
                    minHeight: 8.h,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _calculateProgressValue() {
    if (previousMonthBalance == null) return 0.5;

    // If both are positive or both are negative
    if ((previousMonthBalance! >= 0 && balance >= 0) ||
        (previousMonthBalance! < 0 && balance < 0)) {
      final min = math.min(previousMonthBalance!.abs(), balance.abs());
      final max = math.max(previousMonthBalance!.abs(), balance.abs());

      if (max == 0) return 0.5;

      // Normalize between 0.2 and 0.8 to make it visible
      double ratio = min / max;
      return previousMonthBalance! < balance
          ? 0.5 + (ratio * 0.3)
          : 0.5 - (ratio * 0.3);
    }

    // If one is positive and one is negative
    return previousMonthBalance! < 0 ? 0.7 : 0.3;
  }
}

/// Card showing income and expenses summary
class IncomeExpenseCard extends StatelessWidget {
  final double income;
  final double expense;
  final Currency currency;
  final bool showHeader;

  const IncomeExpenseCard({
    super.key,
    required this.income,
    required this.expense,
    required this.currency,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: 2,
    );

    final double netCashflow = income - expense;
    final bool isPositiveCashflow = netCashflow >= 0;

    // Calculate expense to income ratio
    final double ratio = income > 0 ? (expense / income) * 100 : 0;

    return Card(
      elevation: 2,
      shadowColor: theme.shadowColor.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Income & Expenses',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
              ),
            ),

            SizedBox(height: 16.h),

            // Income and expense containers
            Row(
              children: [
                Expanded(
                  child: _buildAmountContainer(
                    context,
                    'Income',
                    income,
                    formatter,
                    Colors.green,
                    Icons.arrow_upward,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildAmountContainer(
                    context,
                    'Expense',
                    expense,
                    formatter,
                    Colors.red,
                    Icons.arrow_downward,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Net cashflow section
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: isPositiveCashflow
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Net Cashflow',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        isPositiveCashflow
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 16.r,
                        color: isPositiveCashflow ? Colors.green : Colors.red,
                      ),
                      SizedBox(width: 4.w),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          formatter.format(netCashflow.abs()),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                isPositiveCashflow ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Spending ratio section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monthly spending ratio',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color:
                            _getRatioColor(ratio, theme).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '${ratio.toStringAsFixed(1)}%',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getRatioColor(ratio, theme),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Stack(
                  children: [
                    // Background
                    Container(
                      height: 8.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    // Indicator
                    Container(
                      height: 8.h,
                      width: (ratio / 100) *
                          MediaQuery.of(context).size.width *
                          0.8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getRatioColor(ratio, theme).withValues(alpha: 0.7),
                            _getRatioColor(ratio, theme),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '0%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 10.sp,
                      ),
                    ),
                    Text(
                      '50%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 10.sp,
                      ),
                    ),
                    Text(
                      '100% (Balance)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountContainer(
    BuildContext context,
    String title,
    double amount,
    NumberFormat formatter,
    Color color,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 16.r,
              ),
              SizedBox(width: 4.w),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatter.format(amount),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatioColor(double ratio, ThemeData theme) {
    if (income <= 0) return theme.colorScheme.onSurfaceVariant;

    if (ratio > 90) return Colors.red;
    if (ratio > 70) return Colors.orange;
    if (ratio > 50) return Colors.amber;
    return Colors.green;
  }
}

/// Card showing expense to income ratio
class ExpenseRatioCard extends StatelessWidget {
  final double expenseToIncomeRatio;
  final double income;
  final double expense;

  const ExpenseRatioCard({
    super.key,
    required this.expenseToIncomeRatio,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardCard(
      title: 'Expense to Income Ratio',
      height: 160.h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly spending ratio',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                income > 0
                    ? '${expenseToIncomeRatio.toStringAsFixed(1)}%'
                    : 'N/A',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getRatioColor(expenseToIncomeRatio, theme),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (income > 0) ...[
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          // Background track
                          Container(
                            height: 10.h,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(5.r),
                            ),
                          ),
                          // Progress indicator
                          Container(
                            height: 10.h,
                            width:
                                (expenseToIncomeRatio / 100).clamp(0.0, 1.0) *
                                    constraints.maxWidth,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _getRatioGradient(expenseToIncomeRatio),
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(5.r),
                            ),
                          ),
                          // Target indicator for 100%
                          Positioned(
                            left: constraints.maxWidth * 0.8,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 2.w,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(1.r),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '0%',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            '50%',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            '100% (Balance)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ] else ...[
            Expanded(
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'No income recorded this month',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getRatioColor(double ratio, ThemeData theme) {
    if (income <= 0) return theme.colorScheme.onSurfaceVariant;

    if (ratio > 100) return Colors.red;
    if (ratio > 75) return Colors.orange;
    return Colors.green;
  }

  List<Color> _getRatioGradient(double ratio) {
    if (ratio > 100) {
      return [Colors.red, Colors.redAccent];
    } else if (ratio > 75) {
      return [Colors.orange, Colors.orangeAccent];
    } else {
      return [Colors.green, Colors.greenAccent];
    }
  }
}

/// Card showing daily spending trend chart
class DailySpendingCard extends StatelessWidget {
  final Map<int, double> dailyExpenses;
  final Currency currency;

  const DailySpendingCard({
    super.key,
    required this.dailyExpenses,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: 2,
    );

    // Calculate insights
    final entries = dailyExpenses.entries.toList();
    entries.sort((a, b) => a.key.compareTo(b.key));

    double highestSpending = 0;
    int highestSpendingDay = 0;
    double totalSpending = 0;
    double avgSpending = 0;
    double lowestSpending = double.infinity;
    int lowestSpendingDay = 0;

    // For trend analysis
    List<double> weeklyTrends = [];
    double weekSum = 0;
    int weekDays = 0;

    if (entries.isNotEmpty) {
      for (final entry in entries) {
        totalSpending += entry.value;

        if (entry.value > highestSpending) {
          highestSpending = entry.value;
          highestSpendingDay = entry.key;
        }

        if (entry.value > 0 && entry.value < lowestSpending) {
          lowestSpending = entry.value;
          lowestSpendingDay = entry.key;
        }

        // Calculate weekly averages for trend analysis
        weekSum += entry.value;
        weekDays++;
        if (weekDays == 7) {
          weeklyTrends.add(weekSum / 7);
          weekSum = 0;
          weekDays = 0;
        }
      }

      // Add remaining days as a partial week
      if (weekDays > 0) {
        weeklyTrends.add(weekSum / weekDays);
      }

      avgSpending = totalSpending / entries.length;
    }

    // Determine spending trend
    String trendText = 'Stable';
    IconData trendIcon = Icons.trending_flat;
    Color trendColor = Colors.blue;

    if (weeklyTrends.length > 1) {
      final lastWeek = weeklyTrends.last;
      final previousWeek = weeklyTrends[weeklyTrends.length - 2];
      final percentChange = previousWeek > 0
          ? ((lastWeek - previousWeek) / previousWeek) * 100
          : (lastWeek > 0 ? 100 : 0);

      if (percentChange > 10) {
        trendText = 'Increasing';
        trendIcon = Icons.trending_up;
        trendColor = Colors.red;
      } else if (percentChange < -10) {
        trendText = 'Decreasing';
        trendIcon = Icons.trending_down;
        trendColor = Colors.green;
      }
    }

    return Card(
      elevation: 2,
      shadowColor: theme.shadowColor.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Spending Trend',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendIcon,
                        color: trendColor,
                        size: 14.r,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        trendText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: trendColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Insight cards row
            Row(
              children: [
                Expanded(
                  child: _buildInsightCard(
                    context,
                    'Peak Day',
                    highestSpendingDay.toString(),
                    formatter.format(highestSpending),
                    Icons.arrow_circle_up,
                    Colors.orange,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildInsightCard(
                    context,
                    'Daily Avg',
                    '',
                    formatter.format(avgSpending),
                    Icons.show_chart,
                    theme.colorScheme.primary,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildInsightCard(
                    context,
                    'Total',
                    '',
                    formatter.format(totalSpending),
                    Icons.account_balance_wallet,
                    Colors.deepPurple,
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // Chart with fixed height instead of Expanded
            SizedBox(
              height: 220.h,
              child: entries.isEmpty
                  ? _buildEmptyState(context)
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 1,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: theme.dividerColor.withValues(alpha: 0.2),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              getTitlesWidget: (value, meta) {
                                // Show only some days to avoid overcrowding
                                if (value % 5 != 0) return const SizedBox();
                                return Padding(
                                  padding: EdgeInsets.only(top: 8.h),
                                  child: Text(
                                    value.toInt().toString(),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: false,
                        ),
                        minX: entries.isNotEmpty
                            ? entries.first.key.toDouble() - 1
                            : 0,
                        maxX: entries.isNotEmpty
                            ? entries.last.key.toDouble() + 1
                            : 30,
                        lineBarsData: [
                          LineChartBarData(
                            spots: entries
                                .map((entry) =>
                                    FlSpot(entry.key.toDouble(), entry.value))
                                .toList(),
                            isCurved: true,
                            color: theme.colorScheme.primary,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                // Highlight the highest spending day
                                if (spot.x.toInt() == highestSpendingDay) {
                                  return FlDotCirclePainter(
                                    radius: 6,
                                    color: Colors.white,
                                    strokeWidth: 2,
                                    strokeColor: Colors.orange,
                                  );
                                }
                                // Highlight the lowest spending day (if not zero)
                                if (lowestSpending < double.infinity &&
                                    spot.x.toInt() == lowestSpendingDay &&
                                    spot.y > 0) {
                                  return FlDotCirclePainter(
                                    radius: 5,
                                    color: Colors.white,
                                    strokeWidth: 2,
                                    strokeColor: Colors.green,
                                  );
                                }
                                return FlDotCirclePainter(
                                  radius: 3,
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.5),
                                  strokeWidth: 1,
                                  strokeColor: theme.colorScheme.primary,
                                );
                              },
                              checkToShowDot: (spot, barData) {
                                // Show dots only for days with spending
                                return spot.y > 0;
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary
                                      .withValues(alpha: 0.3),
                                  theme.colorScheme.primary
                                      .withValues(alpha: 0.05),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          // Add trend line (7-day moving average)
                          if (entries.length > 7)
                            _buildTrendLine(entries, theme),
                        ],
                        lineTouchData: LineTouchData(
                          enabled: true,
                          touchTooltipData: LineTouchTooltipData(
                            // tooltipBgColor:
                            //     theme.colorScheme.surface.withValues(alpha:0.9),
                            tooltipBorderRadius: BorderRadius.circular(8.r),
                            tooltipPadding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 8.h),
                            getTooltipItems:
                                (List<LineBarSpot> touchedBarSpots) {
                              return touchedBarSpots.map((barSpot) {
                                final day = barSpot.x.toInt();

                                // Different styling for trend line
                                if (barSpot.barIndex == 1) {
                                  return LineTooltipItem(
                                    'Avg: ${formatter.format(barSpot.y)}',
                                    theme.textTheme.bodySmall!.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.purple,
                                    ),
                                  );
                                }

                                return LineTooltipItem(
                                  'Day $day: ${formatter.format(barSpot.y)}',
                                  theme.textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
            ),

            // Legend for trend line
            if (entries.length > 7)
              Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12.w,
                      height: 3.h,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Daily Spending',
                      style: theme.textTheme.bodySmall,
                    ),
                    SizedBox(width: 16.w),
                    Container(
                      width: 12.w,
                      height: 3.h,
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '7-day Average',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(
    BuildContext context,
    String title,
    String subtitle,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16.r,
                color: color,
              ),
              SizedBox(width: 6.w),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              if (subtitle.isNotEmpty) ...[
                Text(
                  subtitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 4.w),
              ],
              Expanded(
                child: Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 48.r,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          SizedBox(height: 16.h),
          Text(
            'No daily spending data available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildTrendLine(
      List<MapEntry<int, double>> entries, ThemeData theme) {
    // Calculate 7-day moving average
    List<FlSpot> trendSpots = [];

    for (int i = 0; i < entries.length; i++) {
      if (i >= 6) {
        // Need at least 7 days for the average
        double sum = 0;
        for (int j = i - 6; j <= i; j++) {
          sum += entries[j].value;
        }
        double avg = sum / 7;
        trendSpots.add(FlSpot(entries[i].key.toDouble(), avg));
      }
    }

    return LineChartBarData(
      spots: trendSpots,
      isCurved: true,
      color: Colors.purple.withValues(alpha: 0.7),
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      dashArray: [5, 5], // Create dashed line
    );
  }
}

/// Widget displaying the empty state when no data is available
class EmptyStateCard extends StatelessWidget {
  final String month;

  const EmptyStateCard({
    super.key,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardCard(
      title: 'No Data Available',
      height: 200.h,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
              size: 48.r,
            ),
            SizedBox(height: 16.h),
            Text(
              'No transactions for $month',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Add income and expenses to see your summary',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Card showing month-to-month comparison with trend analysis
class MonthComparisonCard extends StatelessWidget {
  final Map<String, double>? previousMonthCategories;
  final Map<String, double>? currentMonthCategories;
  final Currency currency;
  final double previousMonthTotal;
  final double currentMonthTotal;

  const MonthComparisonCard({
    super.key,
    required this.previousMonthCategories,
    required this.currentMonthCategories,
    required this.currency,
    required this.previousMonthTotal,
    required this.currentMonthTotal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: 2,
    );

    // No data case
    if (previousMonthCategories == null ||
        currentMonthCategories == null ||
        previousMonthCategories!.isEmpty ||
        currentMonthCategories!.isEmpty) {
      return _buildEmptyCard(context);
    }

    // Find significant changes
    final List<MapEntry<String, Map<String, dynamic>>> categoryChanges = [];

    // Calculate differences for all categories
    final Set<String> allCategories = {
      ...previousMonthCategories!.keys,
      ...currentMonthCategories!.keys
    };

    for (final category in allCategories) {
      final previousAmount = previousMonthCategories![category] ?? 0;
      final currentAmount = currentMonthCategories![category] ?? 0;
      final difference = currentAmount - previousAmount;

      // Skip negligible changes
      if (difference.abs() < 10) continue;

      final percentChange = previousAmount > 0
          ? (difference / previousAmount) * 100
          : (difference > 0 ? 100 : 0);

      final status = difference > 0 ? 'increase' : 'decrease';

      categoryChanges.add(
        MapEntry(
          category,
          {
            'previousAmount': previousAmount,
            'currentAmount': currentAmount,
            'difference': difference,
            'percentChange': percentChange,
            'status': status,
          },
        ),
      );
    }

    // Sort by absolute percentage change
    categoryChanges.sort((a, b) => b.value['percentChange']
        .abs()
        .compareTo(a.value['percentChange'].abs()));

    // Calculate overall trend
    final overallChange = previousMonthTotal > 0
        ? ((currentMonthTotal - previousMonthTotal) / previousMonthTotal) * 100
        : (currentMonthTotal > 0 ? 100 : 0);
    final isPositiveChange = currentMonthTotal >= previousMonthTotal;

    // Monthly trend data for chart
    final List<double> trendData = [previousMonthTotal, currentMonthTotal];

    return Card(
      elevation: 2,
      shadowColor: theme.shadowColor.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Month-to-Month Analysis',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'vs Last Month',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // Overall trend visualization
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trend indicator
                Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: isPositiveChange
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositiveChange
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: isPositiveChange ? Colors.red : Colors.green,
                          size: 24.r,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${overallChange.abs().toStringAsFixed(1)}%',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isPositiveChange ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 16.w),

                // Trend description and chart
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPositiveChange
                            ? 'Spending has increased'
                            : 'Spending has decreased',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isPositiveChange ? Colors.red : Colors.green,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'From ${formatter.format(previousMonthTotal)} to ${formatter.format(currentMonthTotal)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      SizedBox(
                        height: 40.h,
                        child: _buildTrendChart(
                            context, trendData, isPositiveChange),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // Top changes section header
            Text(
              'Top Changes by Category',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 12.h),

            // Category changes list - fixed height instead of Expanded
            SizedBox(
              height: 220.h,
              child: categoryChanges.isEmpty
                  ? Center(
                      child: Text(
                        'No significant category changes found',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: categoryChanges.length > 5
                          ? 5
                          : categoryChanges.length,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        final category = categoryChanges[index];
                        final isIncrease =
                            category.value['status'] == 'increase';

                        return _buildCategoryChangeItem(
                          context,
                          category.key,
                          category.value['previousAmount'],
                          category.value['currentAmount'],
                          category.value['percentChange'],
                          isIncrease,
                          formatter,
                        );
                      },
                    ),
            ),

            // Additional insights
            if (categoryChanges.isNotEmpty)
              Container(
                margin: EdgeInsets.only(top: 16.h),
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Key Insight',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _generateInsight(categoryChanges, isPositiveChange),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChangeItem(
    BuildContext context,
    String category,
    double previousAmount,
    double currentAmount,
    double percentChange,
    bool isIncrease,
    NumberFormat formatter,
  ) {
    final theme = Theme.of(context);
    final color = isIncrease ? Colors.red : Colors.green;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  category,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                      color: color,
                      size: 12.r,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${percentChange.abs().toStringAsFixed(1)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Month',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      formatter.format(previousAmount),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                size: 16.r,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'This Month',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      formatter.format(currentAmount),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(
    BuildContext context,
    List<double> trendData,
    bool isIncrease,
  ) {
    final theme = Theme.of(context);
    final color = isIncrease ? Colors.red : Colors.green;

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, 40.h),
          painter: _TrendChartPainter(
            values: trendData,
            color: color,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        );
      },
    );
  }

  String _generateInsight(
    List<MapEntry<String, Map<String, dynamic>>> categoryChanges,
    bool isOverallIncrease,
  ) {
    if (categoryChanges.isEmpty) {
      return 'No significant changes in spending patterns detected.';
    }

    // Get the top change category
    final topChange = categoryChanges.first;
    final isTopIncrease = topChange.value['status'] == 'increase';
    final topPercentChange = topChange.value['percentChange'].abs();

    if (isOverallIncrease) {
      if (isTopIncrease) {
        return 'Your spending has increased overall, with "${topChange.key}" showing the most significant rise (${topPercentChange.toStringAsFixed(1)}%). Consider reviewing this category to manage expenses better.';
      } else {
        return 'Despite overall spending increase, you\'ve managed to reduce "${topChange.key}" expenses by ${topPercentChange.toStringAsFixed(1)}%. Other categories have increased to offset this saving.';
      }
    } else {
      if (isTopIncrease) {
        return 'Your "${topChange.key}" spending has increased by ${topPercentChange.toStringAsFixed(1)}%, even though your overall spending has decreased. Consider monitoring this category closely.';
      } else {
        return 'Great job! Your overall spending has decreased, with the biggest reduction in "${topChange.key}" (${topPercentChange.toStringAsFixed(1)}% less than last month).';
      }
    }
  }

  Widget _buildEmptyCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shadowColor: theme.shadowColor.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Month-to-Month Analysis',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.insert_chart_outlined,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      size: 48.r,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Insufficient data for comparison',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'We need at least two months of data to show comparison',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for trend chart
class _TrendChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final Color backgroundColor;

  _TrendChartPainter({
    required this.values,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final bgPaint = Paint()
      ..color = backgroundColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final double maxValue = values.reduce(math.max);
    final double minValue = values.reduce(math.min);
    final double range = maxValue - minValue > 0 ? maxValue - minValue : 1;

    // Draw background line
    final bgPath = Path();
    bgPath.moveTo(0, size.height / 2);
    bgPath.lineTo(size.width, size.height / 2);
    canvas.drawPath(bgPath, bgPaint);

    // Calculate points
    final List<Offset> points = [];
    for (int i = 0; i < values.length; i++) {
      final double x = i * (size.width / (values.length - 1));

      // Normalize value to fit in canvas height with padding
      double normalizedValue = (values[i] - minValue) / range;
      // Invert Y axis (0 is top in canvas)
      final double y = size.height -
          (normalizedValue * (size.height * 0.8) + (size.height * 0.1));

      points.add(Offset(x, y));
    }

    // Draw trend line
    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }

      canvas.drawPath(path, paint);
    }

    // Draw dots at data points
    for (var point in points) {
      canvas.drawCircle(point, 4.0, dotPaint);
      canvas.drawCircle(point, 2.0, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

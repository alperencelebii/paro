import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finance_track/core/localization/localization.dart';

import '../../../core/models/currency_model.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/income_model.dart';

/// Widget for displaying the monthly summary card with enhanced analytics
class MonthlySummaryCard extends StatelessWidget {
  final double income;
  final double expense;
  final double balance;
  final Currency currency;
  final double expenseToIncomeRatio;
  final String month;
  final String year;
  final Map<String, double>? categoryBreakdown;
  final Map<int, double>? dailyExpenses;
  final double? previousMonthBalance;

  const MonthlySummaryCard({
    super.key,
    required this.income,
    required this.expense,
    required this.balance,
    required this.currency,
    required this.expenseToIncomeRatio,
    required this.month,
    required this.year,
    this.categoryBreakdown,
    this.dailyExpenses,
    this.previousMonthBalance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: 2,
    );

    // Determine if this is an empty state
    final bool isEmpty = income == 0 && expense == 0;

    // Calculate month-over-month change percentage if previous month data is available

    return Material(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 6.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Stack(
          children: [
            // Decorative elements
            Positioned(
              top: -20.r,
              right: -15.r,
              child: Container(
                width: 100.r,
                height: 100.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -30.r,
              left: -15.r,
              child: Container(
                width: 120.r,
                height: 120.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with improved design
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LocalizedText('$month Summary',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22.sp,
                            ),
                          ),
                          LocalizedText(
                            year,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 16.sp,
                            ),
                          ),
                        ],
                      ),
                      if (!isEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
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
                                balance >= 0
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: balance >= 0
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                size: 16.r,
                              ),
                              SizedBox(width: 6.w),
                              LocalizedText(
                                balance >= 0 ? 'Surplus' : 'Deficit',
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

                  SizedBox(height: 20.h),

                  if (isEmpty)
                    _buildEmptyState(context)
                  else
                    _buildSummaryContent(context, formatter, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.bar_chart,
            color: Colors.white.withValues(alpha: 0.5),
            size: 48.r,
          ),
          SizedBox(height: 16.h),
          LocalizedText('No transactions for $month',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 18.sp,
            ),
          ),
          SizedBox(height: 8.h),
          LocalizedText('Add income and expenses to see your summary',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryContent(
      BuildContext context, NumberFormat formatter, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Balance row with trend indicator
        _buildBalanceSection(formatter, theme),

        SizedBox(height: 24.h),

        // Income and Expense summary
        Row(
          children: [
            Expanded(
              child: _buildSummaryItem(
                context,
                'Income',
                income,
                formatter,
                Colors.greenAccent,
                Icons.arrow_upward_rounded,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _buildSummaryItem(
                context,
                'Expense',
                expense,
                formatter,
                Colors.redAccent,
                Icons.arrow_downward_rounded,
              ),
            ),
          ],
        ),

        SizedBox(height: 24.h),

        // Expense to Income ratio with improved visualization
        if (income > 0 || expense > 0) ...[
          _buildExpenseToIncomeRatio(theme),
          SizedBox(height: 24.h),
        ],

        // Daily spending chart if data is available
        if (dailyExpenses != null && dailyExpenses!.isNotEmpty) ...[
          _buildDailySpendingChart(theme),
          SizedBox(height: 24.h),
        ],

        // Category breakdown if data is available
        if (categoryBreakdown != null && categoryBreakdown!.isNotEmpty) ...[
          _buildCategoryBreakdown(formatter, theme),
        ],
      ],
    );
  }

  Widget _buildBalanceSection(NumberFormat formatter, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalizedText('Balance',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Icon(
                      balance >= 0
                          ? Icons.account_balance_wallet
                          : Icons.account_balance_wallet_outlined,
                      color:
                          balance >= 0 ? Colors.greenAccent : Colors.redAccent,
                      size: 20.r,
                    ),
                    SizedBox(width: 8.w),
                    LocalizedText(
                      formatter.format(balance),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
            if (previousMonthBalance != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      previousMonthBalance! < balance
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: previousMonthBalance! < balance
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      size: 16.r,
                    ),
                    SizedBox(width: 4.w),
                    LocalizedText("${(((balance - previousMonthBalance!) / previousMonthBalance!.abs()) * 100).abs().toStringAsFixed(1)}% ${previousMonthBalance! < balance ? "up" : "down"}",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpenseToIncomeRatio(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            LocalizedText('Expense to Income Ratio',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            LocalizedText(
              income > 0
                  ? '${expenseToIncomeRatio.toStringAsFixed(1)}%'
                  : 'N/A',
              style: TextStyle(
                color: income > 0
                    ? (expenseToIncomeRatio > 100
                        ? Colors.redAccent
                        : Colors.greenAccent)
                    : Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        if (income > 0) ...[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Stack(
                children: [
                  // Background track
                  Container(
                    height: 10.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                  ),
                  // Progress indicator
                  Container(
                    height: 10.h,
                    width: (expenseToIncomeRatio / 100).clamp(0.0, 1.0) *
                        constraints.maxWidth,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: expenseToIncomeRatio > 100
                            ? [Colors.redAccent, Colors.red.shade300]
                            : expenseToIncomeRatio > 75
                                ? [Colors.orangeAccent, Colors.amber]
                                : [Colors.greenAccent, Colors.lightGreenAccent],
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1.r),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              LocalizedText('0%',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10.sp,
                ),
              ),
              LocalizedText('50%',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10.sp,
                ),
              ),
              Row(
                children: [
                  LocalizedText('100%',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  LocalizedText(' (Balance)',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 8.h),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: LocalizedText('No income recorded this month',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDailySpendingChart(ThemeData theme) {
    if (dailyExpenses == null || dailyExpenses!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocalizedText('Daily Spending Trend',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          height: 120.h,
          padding: EdgeInsets.only(top: 8.h, right: 8.w),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      // Show only some days to avoid overcrowding
                      if (value % 5 != 0) return const SizedBox();
                      return Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: LocalizedText(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 10.sp,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: dailyExpenses!.entries
                      .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
                      .toList(),
                  isCurved: true,
                  color: Colors.white,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  // tooltipBgColor: theme.colorScheme.surface.withValues(alpha:0.8),
                  tooltipBorderRadius: BorderRadius.circular(8.r),
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      return LineTooltipItem(
                        '${currency.symbol}${barSpot.y.toStringAsFixed(2)}',
                        TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(NumberFormat formatter, ThemeData theme) {
    if (categoryBreakdown == null || categoryBreakdown!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort categories by amount for the pie chart
    final sortedCategories = categoryBreakdown!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocalizedText('Expense Breakdown by Category',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Pie chart
            SizedBox(
              width: 130.r,
              height: 130.r,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                  sections: _getPieChartSections(sortedCategories),
                  pieTouchData: PieTouchData(enabled: false),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            // Legend
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sortedCategories.take(4).map((category) {
                  final percentage = (category.value / expense) * 100;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Row(
                      children: [
                        Container(
                          width: 10.r,
                          height: 10.r,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(category.key,
                                sortedCategories.indexOf(category)),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: LocalizedText(
                            category.key,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        LocalizedText('${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        if (sortedCategories.length > 4) ...[
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: () {
              // This would be handled by a callback to show detailed breakdown
            },
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LocalizedText('View detailed breakdown',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 12.r,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<PieChartSectionData> _getPieChartSections(
      List<MapEntry<String, double>> categories) {
    // Show top 4 categories, group the rest as "Others"
    if (categories.length <= 4) {
      return categories.asMap().entries.map((entry) {
        final index = entry.key;
        final category = entry.value;

        return PieChartSectionData(
          color: _getCategoryColor(category.key, index),
          value: category.value,
          title: '',
          radius: 50,
          titleStyle: const TextStyle(fontSize: 0),
        );
      }).toList();
    } else {
      // Top 3 + Others
      final topCategories = categories.sublist(0, 3);

      // Calculate total for "Others"
      final othersTotal = categories
          .sublist(3)
          .fold<double>(0, (sum, item) => sum + item.value);

      final result = topCategories.asMap().entries.map((entry) {
        final index = entry.key;
        final category = entry.value;

        return PieChartSectionData(
          color: _getCategoryColor(category.key, index),
          value: category.value,
          title: '',
          radius: 50,
          titleStyle: const TextStyle(fontSize: 0),
        );
      }).toList();

      // Add "Others" section
      result.add(
        PieChartSectionData(
          color: Colors.grey.shade400,
          value: othersTotal,
          title: '',
          radius: 50,
          titleStyle: const TextStyle(fontSize: 0),
        ),
      );

      return result;
    }
  }

  Color _getCategoryColor(String category, int index) {
    // Predefined colors for categories
    const List<Color> colors = [
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.pinkAccent,
      Colors.purpleAccent,
      Colors.blueAccent,
      Colors.amberAccent,
      Colors.tealAccent,
    ];

    return colors[index % colors.length];
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String title,
    double amount,
    NumberFormat formatter,
    Color iconColor,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 14.r,
                ),
              ),
              SizedBox(width: 8.w),
              LocalizedText(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          LocalizedText(
            formatter.format(amount),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying a transaction list item
class TransactionListItem extends StatelessWidget {
  final String title;
  final double amount;
  final DateTime date;
  final dynamic category;
  final Currency currency;
  final bool isExpense;

  const TransactionListItem({
    super.key,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.currency,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: 2,
    );

    // Get category details with null safety
    late IconData categoryIcon;
    late Color categoryColor;
    String categoryName = '';

    try {
      if (isExpense && category is ExpenseCategory) {
        final expenseCategory = category as ExpenseCategory;
        categoryIcon = expenseCategory.icon;
        categoryColor = expenseCategory.color;
        categoryName = expenseCategory.displayName;
      } else if (!isExpense && category is IncomeCategory) {
        final incomeCategory = category as IncomeCategory;
        categoryIcon = incomeCategory.icon;
        categoryColor = incomeCategory.color;
        categoryName = incomeCategory.displayName;
      } else {
        // Fallback for invalid category
        categoryIcon = isExpense ? Icons.shopping_cart : Icons.payments;
        categoryColor =
            isExpense ? theme.colorScheme.error : theme.colorScheme.primary;
        categoryName = isExpense ? 'Expense' : 'Income';
      }
    } catch (e) {
      // Fallback if any error occurs with the category
      categoryIcon = isExpense ? Icons.shopping_cart : Icons.payments;
      categoryColor =
          isExpense ? theme.colorScheme.error : theme.colorScheme.primary;
      categoryName = isExpense ? 'Expense' : 'Income';
    }

    final formattedDate = DateFormat.MMMd().format(date);
    final formattedAmount = isExpense
        ? '-${formatter.format(amount)}'
        : '+${formatter.format(amount)}';
    final amountColor =
        isExpense ? theme.colorScheme.error : theme.colorScheme.primary;

    // Display "No title" if title is empty
    final displayTitle = title.isEmpty ? 'No title' : title;

    return Card(
      elevation: 1,
      shadowColor: Colors.grey.withValues(alpha: 0.2),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(10.r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Category icon
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                categoryIcon,
                color: categoryColor,
                size: 18.r,
              ),
            ),
            SizedBox(width: 10.w),

            // Title and category
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    displayTitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 1.h,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: LocalizedText(
                            categoryName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: categoryColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 10.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Icon(
                        Icons.calendar_today,
                        size: 10.r,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      SizedBox(width: 3.w),
                      LocalizedText(
                        formattedDate,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Amount - responsive width with proper constraints
            Flexible(
              flex: 2,
              child: Container(
                padding: EdgeInsets.only(left: 8.w),
                alignment: Alignment.centerRight,
                child: LocalizedText(
                  formattedAmount,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                    fontSize: 13.sp,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

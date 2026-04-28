import 'package:finance_track/core/extensions/currency_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:finance_track/core/localization/localization.dart';

/// Redesigned BalanceSummaryCard widget matching overall dashboard UI
class BalanceSummaryCard extends StatelessWidget {
  final double balance;
  final double totalIncome;
  final double totalExpense;
  final double incomeChange;
  final double expenseChange;

  const BalanceSummaryCard({
    super.key,
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
    required this.incomeChange,
    required this.expenseChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = context.selectedCurrency;
    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: 2,
    );
    final totalFlow = totalIncome + totalExpense;
    final incomePercentage = totalFlow > 0 ? totalIncome / totalFlow : 0.5;
    final expensePercentage = totalFlow > 0 ? totalExpense / totalFlow : 0.5;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: Title and currency badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                LocalizedText('Total Balance',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12.r),
                    color: Colors.grey.shade100,
                  ),
                  child: Row(
                    children: [
                      LocalizedText(
                        currency.code,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 6.w),
                      LocalizedText(
                        currency.symbol,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontSize: 16.sp),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            LocalizedText('Updated ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            SizedBox(height: 20.h),
            // Main row: Balance and animated pie chart
            Row(
              children: [
                Expanded(
                  child: LocalizedText(
                    formatter.format(balance),
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                SizedBox(
                  width: 70.w,
                  height: 70.w,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: incomePercentage),
                    duration: const Duration(seconds: 1),
                    builder: (context, value, child) {
                      return CustomPaint(
                        painter: _ModernPieChartPainter(
                          incomePercentage: value,
                          expensePercentage: expensePercentage,
                        ),
                        child: Center(
                          child: Icon(
                            balance >= totalExpense
                                ? Icons.savings_outlined
                                : Icons.account_balance_outlined,
                            color: Colors.grey.shade800,
                            size: 28,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            // Income and Expense metric cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Income',
                    amount: totalIncome,
                    change: incomeChange,
                    icon: Icons.arrow_upward,
                    color: Colors.green,
                    formatter: formatter,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Expense',
                    amount: totalExpense,
                    change: expenseChange,
                    icon: Icons.arrow_downward,
                    color: Colors.red,
                    formatter: formatter,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required double amount,
    required double change,
    required IconData icon,
    required Color color,
    required NumberFormat formatter,
  }) {
    final isPositive = (title == 'Income' && change >= 0) ||
        (title == 'Expense' && change < 0);
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8.w),
              LocalizedText(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          LocalizedText(
            formatter.format(amount),
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Icon(isPositive ? Icons.trending_up : Icons.trending_down,
                  color: color, size: 16),
              SizedBox(width: 4.w),
              LocalizedText('${change.abs().toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom Painter for animated modern pie chart matching light dashboard style
class _ModernPieChartPainter extends CustomPainter {
  final double incomePercentage;
  final double expensePercentage;

  _ModernPieChartPainter({
    required this.incomePercentage,
    required this.expensePercentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    const strokeWidth = 6.0;

    // Base circle with light grey color
    final basePaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius - strokeWidth / 2, basePaint);

    // Income arc with green gradient
    final incomePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.greenAccent, Colors.green],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    final incomeSweepAngle = 2 * math.pi * incomePercentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      incomeSweepAngle,
      false,
      incomePaint,
    );

    // Expense arc with red gradient
    final expensePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.redAccent, Colors.red],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    final expenseSweepAngle = 2 * math.pi * expensePercentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2 + incomeSweepAngle,
      expenseSweepAngle,
      false,
      expensePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ModernPieChartPainter oldDelegate) {
    return oldDelegate.incomePercentage != incomePercentage ||
        oldDelegate.expensePercentage != expensePercentage;
  }
}
